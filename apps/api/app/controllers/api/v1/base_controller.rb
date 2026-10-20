module Api
  module V1
    class BaseController < ApplicationController
      include Authentication
    end
  end
end
