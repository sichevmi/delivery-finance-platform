from app.core.security import verify_password
from app.modules.users.models import User


def test_register_success(client, db_session):
    """
    Тест успешной регистрации нового пользователя.
    Проверяем статус 200, наличие id и email в ответе.
    """
    payload = {"email": "new@example.com", "password": "newpass123"}
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == payload["email"]
    assert "id" in data
    # Проверяем, что пользователь действительно создан в БД
    user = db_session.query(User).filter(User.email == payload["email"]).first()
    assert user is not None
    assert verify_password(payload["password"], user.hashed_password)


def test_register_duplicate_email(client, create_test_user, test_user_data):
    """
    Тест: попытка зарегистрироваться с уже существующим email.
    Должен вернуть 400 с сообщением.
    """
    payload = {"email": test_user_data["email"], "password": "anotherpass"}
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 400
    assert response.json()["detail"] == "Email already registered"


def test_register_invalid_email(client):
    """Невалидный email (pydantic валидация) — 422."""
    payload = {"email": "notanemail", "password": "pass"}
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 422


def test_login_success(client, create_test_user, test_user_data):
    """Успешный логин: возвращает access и refresh токены."""
    payload = {"email": test_user_data["email"], "password": test_user_data["password"]}
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client, create_test_user, test_user_data):
    """Логин с неверным паролем — 401."""
    payload = {"email": test_user_data["email"], "password": "wrongpass"}
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 401
    assert response.json()["detail"] == "Incorrect email or password"


def test_login_user_not_found(client):
    """Логин с несуществующим email — 401."""
    payload = {"email": "nonexistent@example.com", "password": "pass"}
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 401
    assert response.json()["detail"] == "Incorrect email or password"


def test_login_missing_fields(client):
    """Отсутствие пароля или email — 422."""
    response = client.post("/api/v1/auth/login", json={"email": "test@example.com"})
    assert response.status_code == 422


def test_hello_with_valid_token(client, create_test_user, test_user_data):
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"email": test_user_data["email"], "password": test_user_data["password"]},
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/api/v1/auth/hello", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Hello World"
    # Проверяем email внутри объекта user
    assert data["user"]["email"] == test_user_data["email"]


def test_hello_with_invalid_token(client):
    """Невалидный токен — 401."""
    headers = {"Authorization": "Bearer invalid_token"}
    response = client.get("/api/v1/auth/hello", headers=headers)
    assert response.status_code == 401


def test_hello_without_token(client):
    """Отсутствие токена — 401."""
    response = client.get("/api/v1/auth/hello")
    assert response.status_code == 403


def test_refresh_token_success(client, create_test_user, test_user_data):
    """Обновление access токена по refresh токену."""
    # Логинимся
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"email": test_user_data["email"], "password": test_user_data["password"]},
    )
    refresh_token = login_resp.json()["refresh_token"]

    response = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    # refresh токен может вернуться тот же или новый, зависит от реализации


def test_refresh_with_invalid_token(client):
    """Невалидный refresh токен — 401."""
    response = client.post("/api/v1/auth/refresh", json={"refresh_token": "invalid"})
    assert response.status_code == 401


def test_logout_success(client, create_test_user, test_user_data):
    """Успешный логаут: отзыв refresh токена."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"email": test_user_data["email"], "password": test_user_data["password"]},
    )
    refresh_token = login_resp.json()["refresh_token"]

    response = client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})
    assert response.status_code == 200
    assert response.json()["message"] == "Logged out"

    # Проверяем, что refresh токен отозван (если есть такая логика)
    # Можно попытаться использовать его для обновления — должно вернуть 401
    refresh_response = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_response.status_code == 401
