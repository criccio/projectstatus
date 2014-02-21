class ProjectsController < ApplicationController

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project].permit(:title))
    if @project.save
      redirect_to @project
    else
      render 'new'
    end
  end

  def edit
    @project = Project.friendly.find(params[:id])
  end

  def update
    @project = Project.friendly.find(params[:id])

    if @project.update(params[:project].permit(:title))
      redirect_to @project
    else
      render 'edit'
    end
  end

  def show
    @project = Project.friendly.find(params[:id])
    @card = Card.new
  end

  def index
    @projects = Project.all
  end

  def destroy
    @project = Project.friendly.find(params[:id])
    @project.destroy

    redirect_to projects_path
  end
end
