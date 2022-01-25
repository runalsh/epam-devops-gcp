

from app import app


def test_answer():
    response = app.test_client().get('/')

    assert response.status_code == 200