module CurationConcerns::CurationConcernController
  extend ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog

  included do
    copy_blacklight_config_from(::CatalogController)
    include CurationConcerns::ThemedLayoutController
    with_themed_layout '1_column'
    helper CurationConcerns::AbilityHelper

    class_attribute :_curation_concern_type, :show_presenter
    self.show_presenter = CurationConcerns::WorkShowPresenter
    attr_accessor :curation_concern
    helper_method :curation_concern
  end

  module ClassMethods
    def set_curation_concern_type(curation_concern_type)
      Deprecation.warn self, "set_curation_concern_type is deprecated and will be removed in curation_concerns 1.0. Use self.curation_concern_type = #{curation_concern_type} instead."
      self.curation_concern_type = curation_concern_type
    end

    def curation_concern_type=(curation_concern_type)
      load_and_authorize_resource class: curation_concern_type, instance_name: :curation_concern, except: [:show, :file_manager]
      self._curation_concern_type = curation_concern_type
    end

    def curation_concern_type
      _curation_concern_type
    end

    def cancan_resource_class
      CurationConcerns::ControllerResource
    end
  end

  def new
    build_form
  end

  def create
    # return unless verify_acceptance_of_user_agreement!
    if actor.create
      after_create_response
    else
      respond_to do |wants|
        wants.html do
          build_form
          render 'new', status: :unprocessable_entity
        end
        wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
      end
    end
  end

  # Finds a solr document matching the id and sets @presenter
  # @raises CanCan::AccessDenied if the document is not found
  #   or the user doesn't have access to it.
  def show
    respond_to do |wants|
      wants.html { presenter }
      wants.json do
        # load and authorize @curation_concern manually because it's skipped for html
        # This has to use #find instead of #load_instance_from_solr because
        # we want to return values like file_set_ids in the json
        @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern
        authorize! :show, @curation_concern
        render :show, status: :ok
      end
      additional_response_formats(wants)
    end
  end

  def edit
    build_form
  end

  def update
    if actor.update
      after_update_response
    else
      respond_to do |wants|
        wants.html do
          build_form
          render 'edit', status: :unprocessable_entity
        end
        wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
      end
    end
  end

  def destroy
    title = curation_concern.to_s
    curation_concern.destroy
    after_destroy_response(title)
  end

  def file_manager
    presenter
  end

  attr_writer :actor

  protected

    # Gives the class of the form. Override this if you want
    # to use a different form.
    def form_class
      CurationConcerns.const_get("#{_curation_concern_type.to_s.demodulize}Form")
    end

    def build_form
      @form = form_class.new(curation_concern, current_ability)
    end

    def actor
      @actor ||= CurationConcerns::CurationConcern.actor(curation_concern, current_user, attributes_for_actor)
    end

    def presenter
      @presenter ||= show_presenter.new(curation_concern_from_search_results, current_ability)
    end

    def _prefixes
      @_prefixes ||= super + ['curation_concerns/base']
    end

    def after_create_response
      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern] }
        wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    def after_update_response
      # TODO: visibility or lease/embargo status
      if curation_concern.visibility_changed? && curation_concern.file_sets.present?
        redirect_to main_app.confirm_curation_concerns_permission_path(curation_concern)
      else
        respond_to do |wants|
          wants.html { redirect_to [main_app, curation_concern] }
          wants.json { render :show, status: :ok, location: polymorphic_path([main_app, curation_concern]) }
        end
      end
    end

    def after_destroy_response(title)
      flash[:notice] = "Deleted #{title}"
      respond_to do |wants|
        wants.html { redirect_to main_app.search_catalog_path }
        wants.json { render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") }
      end
    end

    def attributes_for_actor
      form_class.model_attributes(params[hash_key_for_curation_concern])
    end

    def hash_key_for_curation_concern
      _curation_concern_type.model_name.param_key
    end

    # Override this method to add additional response
    # formats to your local app
    def additional_response_formats(_)
      # nop
    end

    def search_builder_class
      CurationConcerns::WorkSearchBuilder
    end

  private

    def curation_concern_from_search_results
      _, document_list = search_results(params)
      raise CanCan::AccessDenied.new(nil, :show) if document_list.empty?
      document_list.first
    end
end
