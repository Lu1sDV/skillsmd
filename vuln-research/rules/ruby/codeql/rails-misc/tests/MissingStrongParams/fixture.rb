# frozen_string_literal: true

# BAD: direct params[:key] access in controller action — should be flagged
class PoliciesController < ApplicationController
  def new
    @policy_type = params[:type]  # BAD: raw access
  end

  def edit
    @policy_name = URI.decode_www_form_component(params[:id])  # BAD: raw access
    render_404
  end

  def show
    @item = Item.find(params[:id])  # BAD: raw access passed to finder
  end
end

# GOOD: params accessed via permit — should NOT be flagged
class SafePoliciesController < ApplicationController
  def new
    @policy_type = policy_params[:type]  # GOOD: delegated to permitted-params method
  end

  def edit
    @policy_name = URI.decode_www_form_component(policy_params[:id])  # GOOD
    render_404
  end

  def show
    @item = Item.find(params.permit(:id)[:id])  # GOOD: inline permit
  end

  def update
    @item = Item.find(params.require(:item).permit(:name, :value)[:name])  # GOOD: require+permit chain
  end

  private

  def policy_params
    params.permit(:type, :id)
  end
end
