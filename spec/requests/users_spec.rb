require 'rails_helper'

RSpec.describe "/users", type: :request do

  let(:valid_params) {
    {
      name: 'John',
      patronymic: 'Doe',
      surname: 'Smith',
      email: 'john.doe@example.com',
      age: 30,
      nationality: 'American',
      country: 'USA',
      gender: 'Male',
      interests_attributes: [{ name: "Reading" }, { name: "Traveling" }],
      skills_attributes: [{ name: "Ruby" }, { name: "JavaScript" }]
    }
  }

  let(:valid_user) { User.create!(valid_params) }

  let(:invalid_params) {
    {
      name: 'John',
      patronymic: 'Doe',
      surname: 'Smith',
      email: 'invalid_email',
      age: 30,
      nationality: 'American',
      country: 'USA',
      gender: 'Male',
      interests_attributes: [{ name: "Reading" }, { name: "Traveling" }],
      skills_attributes: [{ name: "Ruby" }, { name: "JavaScript" }]
    }
  }

  let(:valid_headers) {
    { content_type: 'application/json' }
  }

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new User" do
        expect {
          puts valid_params.to_json
          post users_url,
               params: { user: valid_params }, headers: valid_headers, as: :json
        }.to change(User, :count).by(1)
        puts response.body
        puts response.status
      end

      it "renders a JSON response with the new user" do
        post users_url,
             params: { user: valid_params }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid parameters" do
      it "does not create a new User" do
        expect {
          post users_url,
               params: { user: invalid_params }, as: :json
        }.to change(User, :count).by(0)
      end

      it "renders a JSON response with errors for the new user" do
        post users_url,
             params: { user: invalid_params }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end
end
