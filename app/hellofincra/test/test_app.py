# tests/test_app.py
import sys
import os

# Add parent directory to path to import app module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import app

def test_hello_index():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200
    assert b'Hello, from MAX!' in response.data