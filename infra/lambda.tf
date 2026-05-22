locals {
  app_source_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../backend/app", "**/*.py")) :
    filesha1("${path.module}/../backend/app/${f}")
  ]))
}

resource "null_resource" "package_lambda" {
  triggers = {
    requirements = filemd5("${path.module}/../backend/requirements.txt")
    app_source   = local.app_source_hash
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ${path.module}/../backend/package
      pip install -r ${path.module}/../backend/requirements.txt \
        -t ${path.module}/../backend/package \
        --quiet \
        --platform manylinux2014_x86_64 \
        --only-binary=:all:
      cp -r ${path.module}/../backend/app/. ${path.module}/../backend/package/
    EOT
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/package"
  output_path = "${path.module}/lambda.zip"
  depends_on  = [null_resource.package_lambda]
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "main.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      SPOTIFY_SECRET_ARN = aws_secretsmanager_secret.spotify_credentials.arn
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}
