# The API reads top-level JSON params; don't also copy them under a model-named key
# (that only produced "Unpermitted parameter" log noise).
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end
