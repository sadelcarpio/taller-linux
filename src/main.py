from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google import genai

client = genai.Client()

class PromptRequest(BaseModel):
    prompt: str

app = FastAPI()


@app.post("/conversar")
def conversar(request: PromptRequest):
    try:
        response = client.models.generate_content(
                model="gemini-2.0-flash-001", contents=request.prompt
            )
        return {"response": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
