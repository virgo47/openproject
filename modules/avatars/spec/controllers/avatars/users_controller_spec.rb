require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../shared_examples")

RSpec.describe Avatars::UsersController do
  include_context "there are users with and without avatars"

  let(:current_user) { create(:admin) }
  let(:enabled) { true }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(OpenProject::Avatars::AvatarManager).to receive(:avatars_enabled?).and_return enabled
  end

  describe ":show" do
    let(:target_user) { user_without_avatar }

    context "as admin" do
      before do
        get :show, params: { id: target_user.id }
      end

      it "renders the edit action" do
        expect(response).to redirect_to edit_user_path(target_user, tab: "avatar")
      end
    end

    context "as another user" do
      let(:current_user) { create(:user) }

      before do
        get :show, params: { id: target_user.id }
      end

      it "renders 403" do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe "#update" do
    let(:target_user) { user_without_avatar }

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "renders 403" do
        post :update, params: { id: target_user.id }
        expect(response).to redirect_to signin_path(back_url: edit_user_avatar_url(target_user))
      end
    end

    context "when not enabled" do
      let(:enabled) { false }

      it "renders 404" do
        put :update, params: { id: target_user.id }
        expect(response).to have_http_status :not_found
      end
    end

    it "returns invalid method for post request" do
      post :update, params: { id: target_user.id }
      expect(response).not_to be_successful
      expect(response).to have_http_status :method_not_allowed
    end

    it "calls the service for put" do
      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:replace)
              .and_return(ServiceResult.success)

      put :update, params: { id: target_user.id }
      expect(response).to be_successful
      expect(response).to have_http_status :ok
    end

    it "calls the service for put" do
      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:replace)
              .and_return(ServiceResult.failure)

      put :update, params: { id: target_user.id }
      expect(response).not_to be_successful
      expect(response).to have_http_status :bad_request
    end
  end

  describe "#delete" do
    let(:target_user) { user_without_avatar }

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "redirect to login" do
        delete :destroy, params: { id: target_user.id }
        expect(response).to redirect_to signin_path(back_url: edit_user_avatar_url(target_user))
      end
    end

    it "returns invalid method for post request" do
      post :destroy, params: { id: target_user.id }
      expect(response).not_to be_successful
      expect(response).to have_http_status :method_not_allowed
    end

    it "calls the service for delete" do
      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:destroy)
              .and_return(ServiceResult.success(result: "message"))

      delete :destroy, params: { id: target_user.id }
      expect(flash[:notice]).to include "message"
      expect(flash[:error]).not_to be_present
      expect(response).to redirect_to controller.send :redirect_path
    end

    it "calls the service for delete" do
      result = ServiceResult.failure
      result.errors.add :base, "error"

      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:destroy)
              .and_return(result)

      delete :destroy, params: { id: target_user.id }
      expect(response).not_to be_successful
      expect(flash[:notice]).not_to be_present
      expect(flash[:error]).to include "error"
      expect(response).to redirect_to controller.send :redirect_path
    end
  end
end
