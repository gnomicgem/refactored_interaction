# frozen_string_literal: true

module Users
  class CreateUser < ActiveInteraction::Base
    string :name, :patronymic, :surname, :nationality, :country, :gender, :email
    integer :age
    array :skills_attributes, :interests_attributes do
      hash do
        string :name
      end
    end

    set_callback :filter, :before, -> {
      self.gender = gender.downcase if gender.present?
    }

    validates :name, :patronymic, :surname, :email, :age, :nationality, :country,
              :gender, presence: true

    validates :email,
              format: { with: URI::MailTo::EMAIL_REGEXP,
                        message: "%{value} is not a valid email" }

    validates :age,
              numericality: { greater_than: 0, less_than_or_equal_to: 90,
                              message: "%{value} is not a valid age" }
    validates :gender,
              inclusion: { in: %w[male female],
                           message: "%{value} is not a valid gender" }

    def execute
      user = User.new(inputs.except(:skills_attributes, :interests_attributes).merge(gender: gender))


      skills = skills_attributes.map { |item| Skill.find_or_initialize_by(name: item[:name]) }
      interests = interests_attributes.map { |item| Interest.find_or_initialize_by(name: item[:name]) }

      run_transaction(user, skills, interests)
      user
    end

    private

    def run_transaction(user, skills, interests)
      ActiveRecord::Base.transaction do
        user.save!
        skills.each(&:save!)
        interests.each(&:save!)
        user.skills.concat(skills)
        user.interests.concat(interests)
        raise ActiveRecord::Rollback if [user, *skills, *interests].any?(&:invalid?)
      end
    end
  end
end
