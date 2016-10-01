require "test_helper"

class TestApisV1WebsiteBackendsAdminPermissions < Minitest::Capybara::Test
  include ApiUmbrellaTests::AdminAuth
  include ApiUmbrellaTests::AdminPermissions
  include ApiUmbrellaTests::Setup

  def setup
    setup_server
    WebsiteBackend.delete_all
  end

  def test_default_permissions
    factory = :website_backend
    assert_default_admin_permissions(factory, :required_permissions => ["backend_manage"], :root_required => true)
  end

  def test_forbids_updating_permitted_backends_with_unpermitted_values
    record = FactoryGirl.create(:website_backend, :frontend_host => "localhost")
    admin = FactoryGirl.create(:localhost_root_admin)

    attributes = record.serializable_hash
    response = Typhoeus.put("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))
    assert_equal(204, response.code, response.body)

    attributes["frontend_host"] = "example.com"
    response = Typhoeus.put("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))
    assert_equal(403, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal(["errors"], data.keys)

    record = WebsiteBackend.find(record.id)
    assert_equal("localhost", record.frontend_host)
  end

  def test_forbids_updating_unpermitted_backends_with_permitted_values
    record = FactoryGirl.create(:website_backend, :frontend_host => "example.com")
    admin = FactoryGirl.create(:localhost_root_admin)

    attributes = record.serializable_hash
    response = Typhoeus.put("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))
    assert_equal(403, response.code, response.body)

    attributes["frontend_host"] = "localhost"
    response = Typhoeus.put("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))
    assert_equal(403, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal(["errors"], data.keys)

    record = WebsiteBackend.find(record.id)
    assert_equal("example.com", record.frontend_host)
  end

  private

  def assert_admin_permitted(factory, admin)
    assert_admin_permitted_index(factory, admin)
    assert_admin_permitted_show(factory, admin)
    assert_admin_permitted_create(factory, admin)
    assert_admin_permitted_update(factory, admin)
    assert_admin_permitted_destroy(factory, admin)
  end

  def assert_admin_forbidden(factory, admin)
    assert_admin_forbidden_index(factory, admin)
    assert_admin_forbidden_show(factory, admin)
    assert_admin_forbidden_create(factory, admin)
    assert_admin_forbidden_update(factory, admin)
    assert_admin_forbidden_destroy(factory, admin)
  end

  def assert_admin_permitted_index(factory, admin)
    record = FactoryGirl.create(factory)
    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/website_backends.json", @@http_options.deep_merge(admin_token(admin)))

    assert_equal(200, response.code, response.body)
    data = MultiJson.load(response.body)
    record_ids = data["data"].map { |r| r["id"] }
    assert_includes(record_ids, record.id)
  end

  def assert_admin_forbidden_index(factory, admin)
    record = FactoryGirl.create(factory)
    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/website_backends.json", @@http_options.deep_merge(admin_token(admin)))

    assert_equal(200, response.code, response.body)
    data = MultiJson.load(response.body)
    record_ids = data["data"].map { |r| r["id"] }
    refute_includes(record_ids, record.id)
  end

  def assert_admin_permitted_show(factory, admin)
    record = FactoryGirl.create(factory)
    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)))

    assert_equal(200, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal(["website_backend"], data.keys)
  end

  def assert_admin_forbidden_show(factory, admin)
    record = FactoryGirl.create(factory)
    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)))

    assert_equal(403, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal(["errors"], data.keys)
  end

  def assert_admin_permitted_create(factory, admin)
    attributes = FactoryGirl.build(factory).serializable_hash
    initial_count = active_count
    response = Typhoeus.post("https://127.0.0.1:9081/api-umbrella/v1/website_backends.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))

    assert_equal(201, response.code, response.body)
    data = MultiJson.load(response.body)
    refute_equal(nil, data["website_backend"]["server_host"])
    assert_equal(attributes["server_host"], data["website_backend"]["server_host"])
    assert_equal(1, active_count - initial_count)
  end

  def assert_admin_forbidden_create(factory, admin)
    attributes = FactoryGirl.build(factory).serializable_hash
    initial_count = active_count
    response = Typhoeus.post("https://127.0.0.1:9081/api-umbrella/v1/website_backends.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))

    assert_equal(403, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal(["errors"], data.keys)
    assert_equal(0, active_count - initial_count)
  end

  def assert_admin_permitted_update(factory, admin)
    record = FactoryGirl.create(factory)

    attributes = record.serializable_hash
    attributes["server_host"] += rand(999_999).to_s
    response = Typhoeus.put("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))

    assert_equal(204, response.code, response.body)
    record = WebsiteBackend.find(record.id)
    refute_equal(nil, record.server_host)
    assert_equal(attributes["server_host"], record.server_host)
  end

  def assert_admin_forbidden_update(factory, admin)
    record = FactoryGirl.create(factory)

    attributes = record.serializable_hash
    attributes["server_host"] += rand(999_999).to_s
    response = Typhoeus.put("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :website_backend => attributes },
    }))

    assert_equal(403, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal(["errors"], data.keys)

    record = WebsiteBackend.find(record.id)
    refute_equal(nil, record.server_host)
    refute_equal(attributes["server_host"], record.server_host)
  end

  def assert_admin_permitted_destroy(factory, admin)
    record = FactoryGirl.create(factory)
    initial_count = active_count
    response = Typhoeus.delete("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)))
    assert_equal(204, response.code, response.body)
    assert_equal(-1, active_count - initial_count)
  end

  def assert_admin_forbidden_destroy(factory, admin)
    record = FactoryGirl.create(factory)
    initial_count = active_count
    response = Typhoeus.delete("https://127.0.0.1:9081/api-umbrella/v1/website_backends/#{record.id}.json", @@http_options.deep_merge(admin_token(admin)))
    assert_equal(403, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal(["errors"], data.keys)
    assert_equal(0, active_count - initial_count)
  end

  def active_count
    WebsiteBackend.where(:deleted_at => nil).count
  end
end