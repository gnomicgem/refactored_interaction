class SkillsController < ApplicationController
  before_action :set_skill, only: %i[ show update destroy ]

  # GET /skils
  def index
    @skills = Skill.all

    render json: @skills
  end

  # GET /skils/1
  def show
    render json: @skill
  end

  # POST /skils
  def create
    @skill = Skill.new(skill_params)

    if @skill.save
      render json: @skill, status: :created, location: @skill
    else
      render json: @skill.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /skils/1
  def update
    if @skill.update(skill_params)
      render json: @skill
    else
      render json: @skill.errors, status: :unprocessable_entity
    end
  end

  # DELETE /skils/1
  def destroy
    @skill.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_skill
      @skill = Skill.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def skill_params
      params.expect(skill: [:name ])
    end
end
