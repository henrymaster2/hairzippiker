import Config

# =========================================================
# PHX SERVER (Production start control)
# =========================================================
if System.get_env("PHX_SERVER") do
  config :hair_zippiker, HairZippikerWeb.Endpoint, server: true
end

# =========================================================
# HTTP CONFIG (PORT from environment)
# =========================================================
config :hair_zippiker, HairZippikerWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT") || "4000")]

# =========================================================
# PRODUCTION CONFIG
# =========================================================
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      Missing DATABASE_URL environment variable.
      Example:
      ecto://USER:PASS@HOST/DATABASE
      """

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      Missing SECRET_KEY_BASE environment variable.
      Generate one with: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  maybe_ipv6 =
    if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # =========================================================
  # DATABASE (FIXED: SSL ENABLED for Render PostgreSQL)
  # =========================================================
  config :hair_zippiker, HairZippiker.Repo,
    url: database_url,
    ssl: true,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # Optional DNS clustering (safe to keep)
  config :hair_zippiker, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # =========================================================
  # ENDPOINT (Production URL config)
  # =========================================================
  config :hair_zippiker, HairZippikerWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

end