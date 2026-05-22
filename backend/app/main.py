from fastapi import FastAPI
from mangum import Mangum
from app.routes.token import router

app = FastAPI()
app.include_router(router)
handler = Mangum(app, lifespan="off")
