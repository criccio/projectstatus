class CardsController < ApplicationController
  def new
    @project = Project.friendly.find(params[:project_id])
    @card = Card.new
  end

  def create
    @project = Project.friendly.find(params[:project_id])
    @card = @project.cards.create(params[:card].permit(:title, :jenkins_url))
    if @card.save
      redirect_to project_path(@project)
    else
      render 'new'
    end
  end

  def destroy
    @project = Project.friendly.find(params[:project_id])
    @card = @project.cards.find(params[:id])
    @card.destroy
    redirect_to project_path(@project)
  end

  def show
    @project = Project.friendly.find(params[:project_id])
    @card = @project.cards.find(params[:id])
  end
end
