class IshManager::GalleriesController < IshManager::ApplicationController

  before_action :set_lists
  
  def index
    authorize! :index, Gallery
    @galleries = Gallery.unscoped.where( :is_trash => false, :user_profile => current_user.profile
                                       ).order_by( :created_at => :desc )

    if params[:render_type] == Gallery::RENDER_TITLES
      render 'index_titles'
      return
    else
      if params[:q]
        @galleries = @galleries.where({ :name => /#{params[:q]}/i })      
      end
      @galleries = @galleries.page( params[:galleries_page] ).per( 20 )
      @shared_galleries = current_user.profile.shared_galleries.unscoped.where( :is_trash => false ).page( params[:shared_galleries_page] ).per( 10 )
    end

  end

=begin
  def index_title
  end
  def index_thumb
    @galleries = Gallery.unscoped.where( :is_trash => false 
                                       ).order_by( :created_at => :desc 
                                                 ).page( params[:galleries_page] ).per( 10 )
  end
  def index_mini
    @galleries = Gallery.unscoped.where( :is_trash => false 
                                       ).order_by( :created_at => :desc 
                                                 ).page( params[:galleries_page] ).per( 10 )
  end
=end

  def new
    @gallery = Gallery.new
    authorize! :new, @gallery
    @cities_list = City.list
    @tags_list = Tag.list
  end

  def create
    params[:gallery][:shared_profiles] ||= []
    params[:gallery][:shared_profiles].delete('')
    params[:gallery][:shared_profiles] = IshModels::UserProfile.find params[:gallery][:shared_profiles]
    @gallery = Gallery.new params[:gallery].permit!
    @gallery.user_profile = current_user.profile
    @gallery.username = current_user.profile.username
    authorize! :create, @gallery

    if @gallery.save
      ::IshManager::ApplicationMailer.shared_galleries( params[:gallery][:shared_profiles], @gallery ).deliver
      flash[:notice] = 'Success'
      redirect_to galleries_path
    else
      puts! @gallery.errors.messages
      flash[:alert] = 'No Luck. ' + @gallery.errors.inspect
      @cities_list = City.list
      @tags_list = Tag.list
      render :action => 'new'
    end
  end

  def edit
    @gallery = Gallery.unscoped.find params[:id]
    authorize! :edit, @gallery
  end

  def update
    @gallery = Gallery.unscoped.find params[:id]
    old_shared_profile_ids = @gallery.shared_profiles.map(&:id)
    authorize! :update, @gallery

    params[:gallery][:shared_profiles].delete('')
    # params[:gallery][:shared_profiles] = IshModels::UserProfile.find( params[:gallery][:shared_profiles] ).to_a
    params[:gallery][:shared_profile_ids] = params[:gallery][:shared_profiles]
    params[:gallery].delete :shared_profiles

    # puts! params[:gallery][:shared_profiles], 'shared profiles'
    if @gallery.update_attributes( params[:gallery].permit! )
      new_shared_profiles = IshModels::UserProfile.find( params[:gallery][:shared_profile_ids] 
                                                       ).select do |p|
        !old_shared_profile_ids.include?( p.id )
      end
      ::IshManager::ApplicationMailer.shared_galleries( new_shared_profiles, @gallery ).deliver
      flash[:notice] = 'Success.'
      redirect_to galleries_path
    else
      puts! @gallery.errors.messages, 'cannot save gallery'
      flash[:alert] = 'No Luck. ' + @gallery.errors.messages.to_s
      render :action => :edit
    end
  end                           

  def show
    begin
      @gallery = Gallery.unscoped.find_by :galleryname => params[:id]
    rescue
      @gallery = Gallery.unscoped.find params[:id]
    end
    authorize! :show, @gallery
    @photos = @gallery.photos.unscoped.where({ :is_trash => false })
    @deleted_photos = @gallery.photos.unscoped.where({ :is_trash => true })
  end

  def destroy
    @gallery = Gallery.unscoped.find params[:id]
    authorize! :destroy, @gallery
    @gallery.is_trash = true
    @gallery.save
    flash[:notice] = 'Logically deleted gallery.'
    redirect_to galleries_path
  end

  def j_show
    @gallery = Gallery.unscoped.find( params[:id] )
    authorize! :show, @gallery
    respond_to do |format|
      format.json do
        jjj = {}
        jjj[:photos] = @gallery.photos.map do |ph|
          { :thumbnail_url => ph.photo.url( :thumb ),
          :delete_type => 'DELETE',
          :delete_url => photo_path(ph) }
        end
        render :json => jjj
      end
    end
  end

end

