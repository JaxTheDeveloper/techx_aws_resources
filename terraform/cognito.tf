# ─── Cognito User Pool ─────────────────────────────────────────────────────────

resource "aws_cognito_user_pool" "dochub" {
  name = "${var.project_name}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # custom:tenant_id attribute stamped on every user
  schema {
    name                     = "tenant_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Pre-Token Generation trigger — injects cognito:groups into JWT
  lambda_config {
    pre_token_generation = aws_lambda_function.pre_token_gen.arn
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  tags = { Name = "${var.project_name}-user-pool" }
}

# ─── Cognito Domain ────────────────────────────────────────────────────────────

resource "aws_cognito_user_pool_domain" "dochub" {
  domain       = "${local.name_prefix}-${local.account_id}"
  user_pool_id = aws_cognito_user_pool.dochub.id
}

# ─── Google OAuth IdP ─────────────────────────────────────────────────────────

resource "aws_cognito_identity_provider" "google" {
  count         = var.google_oauth_client_id != "" ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.dochub.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = var.google_oauth_client_id
    client_secret    = var.google_oauth_client_secret
    authorize_scopes = "openid email profile"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

# ─── App Client ───────────────────────────────────────────────────────────────

resource "aws_cognito_user_pool_client" "dochub" {
  name         = "DocHub"
  user_pool_id = aws_cognito_user_pool.dochub.id

  generate_secret = false

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  supported_identity_providers = concat(
    ["COGNITO"],
    var.google_oauth_client_id != "" ? ["Google"] : []
  )

  callback_urls = [
    for base in local.frontend_base_urls : "${base}/callback"
  ]

  logout_urls = [
    for base in local.frontend_base_urls : "${base}/logout"
  ]

  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  auth_session_validity = 3

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  depends_on = [aws_cognito_identity_provider.google]
}

# ─── Cognito Groups (tenant isolation) ────────────────────────────────────────

resource "aws_cognito_user_group" "tenant_acme" {
  name         = "tenant-acme"
  user_pool_id = aws_cognito_user_pool.dochub.id
  description  = "Tenant: ACME Corp"
}

resource "aws_cognito_user_group" "tenant_globex" {
  name         = "tenant-globex"
  user_pool_id = aws_cognito_user_pool.dochub.id
  description  = "Tenant: Globex Corp"
}
