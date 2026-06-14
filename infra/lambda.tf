locals {
  app_source_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../backend/app", "**/*.py")) :
    filesha1("${path.module}/../backend/app/${f}")
  ]))
}

resource "terraform_data" "package_lambda" {
  triggers_replace = {
    requirements = filemd5("${path.module}/../backend/requirements.txt")
    app_source   = local.app_source_hash
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      rm -rf ${path.module}/../backend/package
      pip install -r ${path.module}/../backend/requirements.txt \
        -t ${path.module}/../backend/package \
        --quiet \
        --platform manylinux2014_x86_64 \
        --python-version 3.12 \
        --implementation cp \
        --only-binary=:all:
      cp -r ${path.module}/../backend/app ${path.module}/../backend/package/app
    EOT
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/package"
  output_path = "${path.module}/../backend/lambda.zip"
  depends_on  = [terraform_data.package_lambda]
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-api"
  retention_in_days = 30
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "app.main.handler"
  runtime          = "python3.12"
  architectures    = ["x86_64"]
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout                        = 15
  memory_size                    = 256
  reserved_concurrent_executions = 100

  environment {
    variables = {
      SPOTIFY_PARAM_NAME = aws_ssm_parameter.spotify_credentials.name
      AUTH0_DOMAIN       = var.auth0_domain
      AUTH0_AUDIENCE     = var.auth0_audience
      USERS_TABLE_NAME   = aws_dynamodb_table.users.name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}
