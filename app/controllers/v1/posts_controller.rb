module V1
  class PostsController < ApplicationController
    before_filter :check_sign_in, except: [:index, :latest, :show]
    before_filter :load_parents, except: [:latest]
    before_filter :check_permissions, except: [:index, :latest, :create, :show]

    def load_parents
      @user = User.find_by_login!(params[:user_id])
      @repo = @user.repos.find_by_name!(params[:repo_id])
      @topic = @repo.topics.find_by_number!(params[:topic_id])
    end

    def check_permissions
      unless current_user == @post.user
        if @user.type == 'User'
          not_authorized unless current_user == @user
        else
          not_authorized unless @user.owners.include?(current_user)
        end
      end
    end

    def to_json(thing)
      thing.to_json({include: {
        user: {},
        topic: {include: {
          repo: {include: :user}
        }}
      }})
    end

    # GET /posts
    # GET /posts.json
    def index
      @posts = @topic.posts.includes(:user, topic: [repo: :user])
      render json: to_json(@posts)
    end

    def latest
      @posts = Post
        .includes(:user, topic: [repo: :user])
        .reverse_order.limit(20)
      render json: to_json(@posts)
    end

    # GET /posts/1
    # GET /posts/1.json
    def show
      @post = Post.find(params[:id])
      render json: to_json(@post)
    end

    # POST /posts
    # POST /posts.json
    def create
      @post = Post.new(params[:post])
      @post.assign_attributes(
        {user: current_user, topic: @topic}, without_protection: true
      )

      if @post.save
        render json: to_json(@post), status: :created
        # The route is buggy. See rails/rails/issues/6564.
        # location: v1_user_repo_topic_post_path(@user, @repo, @topic, @post)
      else
        render json: @post.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /posts/1
    # PATCH/PUT /posts/1.json
    def update
      @post = Post.find(params[:id])

      if @post.update_attributes(params[:post])
        head :no_content
      else
        render json: @post.errors, status: :unprocessable_entity
      end
    end

    # DELETE /posts/1
    # DELETE /posts/1.json
    def destroy
      @post = Post.find(params[:id])
      @post.destroy

      head :no_content
    end
  end
end
