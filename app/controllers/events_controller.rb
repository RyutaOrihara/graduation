class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, only: [:new, :edit, :update, :destroy, :render_index]
  before_action:destroy_message, only: [:destroy]
  before_action:event_organizer_or_admin?, only: [:edit, :update, :destroy]

  def index
    @events = Event.order(e_date_start: :desc).page(params[:page]).per(12)
  end

  def search
     @q = Event.search(search_params)
     @events = @q.result(distinct: true).page(params[:page]).per(25)
  end

  def show
    if user_signed_in?
      @favorite = current_user.favorites.find_by(event_id: @event.id)
      @current_user_parthicipant = current_user.parthicipant_managements.find_by(event_id: @event.id)
      @parthicipante = @event.parthicipant_managements.where(event_id: @event.id)
      @parthicipante_users = @event.parthicipante_users#.where(event_id: @event.id)
    end
  end

  def new
    if params[:back]
      @event = Event.new(event_params)
    else
      @event = Event.new
    end
  end

  def edit
  end

  def create
    @event = current_user.events.build(event_params)
    if params[:back]
        render :new
      else
      if @event.save
        redirect_to events_path, notice:"イベントを作成しました！" #noticeはHTMLに記述しないと表示されない。
      else
        render :new
      end
    end
  end

  def confirm
    @event = current_user.events.build(event_params)
    @label_ids = event_params[:label_ids]
    render :new if @event.invalid?
  end

  def update
    if @event.update(event_params)
      if @event.parthicipante_users.present?
        @event_info = @event
        @event.parthicipante_users.each do|event_parthicipante_user|
          EventChangeMailer.event_change(event_parthicipante_user.email,@event_info).deliver
        end
      end
      redirect_to events_path, notice: "イベントを更新しました！"
    else
      render :edit
    end
  end

  def favorite
    @favorites = current_user.favorite_events
  end

  def parthicipante_events
    @parthicipante_events = current_user.parthicipante_events
  end

  def destroy
    if current_user.admin? || current_user.id == @event.user.id
      @event.destroy
      redirect_to events_path, notice:"イベントを削除しました！"
    end
  end

  def new_guest
    user = User.find_or_create_by!(email: 'guest@example.com',name: "ゲスト太郎") do |user|
      user.password = SecureRandom.urlsafe_base64
      user.confirmed_at = Time.now
    end
    sign_in user
    redirect_to root_path, notice: 'ゲストユーザーとしてログインしました。'
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :content, :image, :image_cache, :e_date_start, :e_date_end, :address, label_ids: [])
  end

  def search_params
    params.require(:q).permit!
  end

  def destroy_message
    @event.parthicipante_users.each do|event|
      EventDestroyMailer.event_destroy(event.email,@event).deliver
    end
  end

  def contact_params
    params.require(:contact).permit(:title, :email, :content, :event_id, :name)
  end

  def event_organizer_or_admin?
    unless current_user.admin? || current_user.id == @event.user.id
      render :index, notice: "イベント主催者以外編集はできません"
    end
  end
end
