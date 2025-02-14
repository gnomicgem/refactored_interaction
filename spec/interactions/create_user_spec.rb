# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::CreateUser, type: :interaction do
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

  let(:outcome) { described_class.run!(valid_params) }

  describe 'inputs_validations' do
    context 'with invalid parameters' do
      it 'fails without required attributes' do
        params = valid_params.merge(name: '')
        expect(described_class.run(params)).to be_invalid
      end

      it 'downcases the gender before validation' do
        expect(outcome.gender).to eq('male')
      end

      it 'fails with an invalid email format' do
        params = valid_params.merge(email: 'invalid-email')
        expect(described_class.run(params)).to be_invalid
      end

      it 'fails with an invalid age' do
        expect(described_class.run(valid_params.merge(age: 0))).to be_invalid
        expect(described_class.run(valid_params.merge(age: 91))).to be_invalid
      end

      it 'fails with an invalid gender' do
        expect(described_class.run(valid_params.merge(gender: 'unknown'))).to be_invalid
      end
    end
  end

  describe '#start_transaction' do
    context 'when a database transaction fails' do
      it 'does not create a user if skills or interests fail to save' do
        allow_any_instance_of(Skill).to receive(:save!).and_raise(ActiveRecord::Rollback)
        expect { described_class.run(valid_params) }.not_to change(User, :count)
      end
    end
  end

  describe '#execute' do
    context 'with valid parameters' do
      it 'creates a user' do
        expect { described_class.run!(valid_params) }.to change(User, :count).by(1)
      end

      it 'creates associated skills and interests' do
        expect { described_class.run!(valid_params) }.to change(Skill, :count).by(2).and change(Interest, :count).by(2)
      end

      it 'associates skills and interests with the user' do
        expect(outcome.skills.map(&:name)).to include('Ruby')
        expect(outcome.interests.map(&:name)).to include('Reading')
      end
    end
  end
end
