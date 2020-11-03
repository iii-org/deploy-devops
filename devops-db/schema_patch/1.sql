ALTER TABLE public.flow ADD CONSTRAINT flow_pkey PRIMARY KEY (id);
ALTER TABLE public.http_method ADD CONSTRAINT http_method_pkey PRIMARY KEY (id);
ALTER TABLE public.parameter_types ADD CONSTRAINT parameter_types_pkey PRIMARY KEY (id);
ALTER TABLE public.parameters ADD CONSTRAINT parameters_pkey PRIMARY KEY (id);
ALTER TABLE public.requirements ADD CONSTRAINT requirements_pkey PRIMARY KEY (id);
ALTER TABLE public.test_cases ADD CONSTRAINT test_cases_pkey PRIMARY KEY (id);
ALTER TABLE public.test_cases_type ADD CONSTRAINT test_cases_type_pkey PRIMARY KEY (id);
ALTER TABLE public.test_items ADD CONSTRAINT test_items_pkey PRIMARY KEY (id);
ALTER TABLE public.test_values ADD CONSTRAINT test_values_pkey PRIMARY KEY (id);
ALTER TABLE public.groups_has_users ADD CONSTRAINT groups_has_users_pkey PRIMARY KEY (id);
ALTER TABLE public.roles_plugin_relation ADD CONSTRAINT roles_plugin_relation_pkey PRIMARY KEY (id);
ALTER TABLE public.user_plugin_relation ADD CONSTRAINT user_plugin_relation_pkey PRIMARY KEY (id);
ALTER TABLE public.db_version ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);

UPDATE public.db_version SET "version"=1;