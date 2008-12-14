class UsersController < ApplicationController

  
before_filter :check_authorized, :only => [:new]
  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      self.current_user = @user
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end
  
  protected
  
  def check_authorized
    @users = User.find(:all)
    
    if !@users.empty? && !authorized?
      redirect_to login_path
    end   
  end
end
