# routing
Rails.application.routes.draw do
  resources :projects do
    resources :evms, :evmbaselines, :evmsettings, :evmassignees, :evmparentissues, :evmversions, :evmtrackers, :evmexcludes,
              :evmbaselinediffdetails, :evmreports
  end
end
