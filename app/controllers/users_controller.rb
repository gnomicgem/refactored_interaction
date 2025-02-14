class UsersController < ApplicationController

  # POST /users
  def create
    outcome = Users::CreateUser.run(user_params)

    if outcome.valid?
      render json: outcome.result, status: 201, location: outcome.result
    else
      render json: outcome.errors, status: 422
    end
  end

  private
    def user_params
      params.require(:user).permit(
        :name, :patronymic, :surname, :email, :age, :nationality, :country, :gender,
        skills_attributes: [:name],
        interests_attributes: [:name]
      )
    end
end
