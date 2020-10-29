--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3 (Debian 12.3-1.pgdg100+1)
-- Dumped by pg_dump version 13.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: checkmarx; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.checkmarx (
    scan_id integer NOT NULL,
    report_id integer DEFAULT '-1'::integer,
    repo_id integer,
    cm_project_id integer NOT NULL,
    run_at timestamp without time zone,
    finished_at timestamp without time zone,
    finished boolean DEFAULT false
);


ALTER TABLE public.checkmarx OWNER TO postgres;

--
-- Name: files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.files (
    id integer NOT NULL,
    type character varying(45),
    name character varying(45),
    state character varying(45),
    file text,
    editor_id integer,
    create_at timestamp without time zone,
    upload_at timestamp without time zone,
    project_id integer,
    issue_id integer,
    version_id integer
);


ALTER TABLE public.files OWNER TO postgres;

--
-- Name: flows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flows (
    id integer NOT NULL,
    project_id integer,
    issue_id integer,
    requirement_id integer,
    type_id integer,
    name character varying(30),
    description character varying(100),
    serial_id integer,
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false
);


ALTER TABLE public.flows OWNER TO postgres;

--
-- Name: COLUMN flows.type_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.flows.type_id IS '["Given","When","Then","But","And"]';


--
-- Name: flows_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.flows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flows_id_seq OWNER TO postgres;

--
-- Name: flows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.flows_id_seq OWNED BY public.flows.id;


--
-- Name: group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."group" (
    id integer NOT NULL,
    name character varying(45),
    description character varying(100),
    create_at timestamp without time zone,
    update_at timestamp without time zone
);


ALTER TABLE public."group" OWNER TO postgres;

--
-- Name: group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_id_seq OWNER TO postgres;

--
-- Name: group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_id_seq OWNED BY public."group".id;


--
-- Name: group_parent_child; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_parent_child (
    id integer NOT NULL,
    group_parent_id integer NOT NULL,
    group_child_id integer NOT NULL
);


ALTER TABLE public.group_parent_child OWNER TO postgres;

--
-- Name: groups_has_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.groups_has_users (
    group_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.groups_has_users OWNER TO postgres;

--
-- Name: http_method; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.http_method (
    id integer NOT NULL,
    type character varying(50)
);


ALTER TABLE public.http_method OWNER TO postgres;

--
-- Name: http_method_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.http_method_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.http_method_id_seq OWNER TO postgres;

--
-- Name: http_method_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.http_method_id_seq OWNED BY public.http_method.id;


--
-- Name: parameter_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parameter_types (
    id integer NOT NULL,
    type character varying(30)
);


ALTER TABLE public.parameter_types OWNER TO postgres;

--
-- Name: parameter_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parameter_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parameter_types_id_seq OWNER TO postgres;

--
-- Name: parameter_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parameter_types_id_seq OWNED BY public.parameter_types.id;


--
-- Name: parameters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parameters (
    id integer NOT NULL,
    parameter_type_id integer,
    name character varying(50),
    description character varying(100),
    limitation character varying(50),
    length integer,
    issue_id integer,
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false,
    project_id integer
);


ALTER TABLE public.parameters OWNER TO postgres;

--
-- Name: parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parameters_id_seq OWNER TO postgres;

--
-- Name: parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parameters_id_seq OWNED BY public.parameters.id;


--
-- Name: pipeline_phase; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pipeline_phase (
    id integer NOT NULL,
    name character varying NOT NULL,
    description character varying,
    "parent_phase_Id" integer,
    is_closed boolean DEFAULT false
);


ALTER TABLE public.pipeline_phase OWNER TO postgres;

--
-- Name: pipeline_software; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pipeline_software (
    id integer NOT NULL,
    name character varying,
    phase_id integer,
    is_closed boolean DEFAULT false NOT NULL,
    description character varying
);


ALTER TABLE public.pipeline_software OWNER TO postgres;

--
-- Name: pipeline_software_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pipeline_software_config (
    id integer NOT NULL,
    software_id integer NOT NULL,
    project_id integer,
    detail text,
    sample boolean DEFAULT true
);


ALTER TABLE public.pipeline_software_config OWNER TO postgres;

--
-- Name: project_plugin_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_plugin_relation (
    project_id integer NOT NULL,
    plan_project_id integer,
    git_repository_id integer,
    ci_project_id character varying,
    ci_pipeline_id character varying
);


ALTER TABLE public.project_plugin_relation OWNER TO postgres;

--
-- Name: project_user_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_user_role (
    project_id integer,
    user_id integer NOT NULL,
    role_id integer NOT NULL
);


ALTER TABLE public.project_user_role OWNER TO postgres;

--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id integer NOT NULL,
    name character varying(45),
    email character varying(45),
    phone character varying(40),
    login character varying(45),
    password character varying(100),
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_id_seq OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer DEFAULT nextval('public.user_id_seq'::regclass) NOT NULL,
    name character varying,
    description character varying,
    ssh_url character varying,
    http_url character varying,
    start_date date,
    due_date date,
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false NOT NULL,
    display character varying
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: requirements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.requirements (
    id integer NOT NULL,
    project_id integer,
    issue_id integer,
    flow_info text,
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false NOT NULL
);


ALTER TABLE public.requirements OWNER TO postgres;

--
-- Name: requirements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.requirements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requirements_id_seq OWNER TO postgres;

--
-- Name: requirements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.requirements_id_seq OWNED BY public.requirements.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_plugin_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles_plugin_relation (
    role_id integer NOT NULL,
    plan_role_id integer NOT NULL
);


ALTER TABLE public.roles_plugin_relation OWNER TO postgres;

--
-- Name: test_cases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_cases (
    id integer NOT NULL,
    name character varying(100),
    description character varying(255),
    issue_id integer,
    project_id integer,
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false NOT NULL,
    data text,
    type_id integer
);


ALTER TABLE public.test_cases OWNER TO postgres;

--
-- Name: test_cases_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.test_cases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.test_cases_id_seq OWNER TO postgres;

--
-- Name: test_cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.test_cases_id_seq OWNED BY public.test_cases.id;


--
-- Name: test_cases_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_cases_type (
    id integer NOT NULL,
    name character varying
);


ALTER TABLE public.test_cases_type OWNER TO postgres;

--
-- Name: test_cases_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.test_cases_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.test_cases_type_id_seq OWNER TO postgres;

--
-- Name: test_cases_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.test_cases_type_id_seq OWNED BY public.test_cases_type.id;


--
-- Name: test_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.test_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.test_items_id_seq OWNER TO postgres;

--
-- Name: test_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_items (
    id integer DEFAULT nextval('public.test_items_id_seq'::regclass) NOT NULL,
    issue_id integer,
    project_id integer,
    name character varying(255),
    is_passed boolean DEFAULT true NOT NULL,
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false NOT NULL,
    test_case_id integer
);


ALTER TABLE public.test_items OWNER TO postgres;

--
-- Name: test_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_results (
    id integer NOT NULL,
    project_id integer,
    branch character varying(50),
    total integer,
    fail integer,
    run_at timestamp without time zone
);


ALTER TABLE public.test_results OWNER TO postgres;

--
-- Name: COLUMN test_results.fail; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.test_results.fail IS 'faiue test';


--
-- Name: test_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.test_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.test_results_id_seq OWNER TO postgres;

--
-- Name: test_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.test_results_id_seq OWNED BY public.test_results.id;


--
-- Name: test_values; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_values (
    id integer NOT NULL,
    type_id integer,
    key character varying(50),
    value text,
    location_id integer,
    test_item_id integer,
    test_case_id integer,
    issue_id integer,
    project_id integer,
    create_at timestamp without time zone,
    update_at timestamp without time zone,
    disabled boolean DEFAULT false
);


ALTER TABLE public.test_values OWNER TO postgres;

--
-- Name: test_values_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.test_values_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.test_values_id_seq OWNER TO postgres;

--
-- Name: test_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.test_values_id_seq OWNED BY public.test_values.id;


--
-- Name: user_plugin_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_plugin_relation (
    user_id integer,
    plan_user_id integer,
    repository_user_id integer
);


ALTER TABLE public.user_plugin_relation OWNER TO postgres;

--
-- Name: flows id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flows ALTER COLUMN id SET DEFAULT nextval('public.flows_id_seq'::regclass);


--
-- Name: group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."group" ALTER COLUMN id SET DEFAULT nextval('public.group_id_seq'::regclass);


--
-- Name: http_method id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.http_method ALTER COLUMN id SET DEFAULT nextval('public.http_method_id_seq'::regclass);


--
-- Name: parameter_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameter_types ALTER COLUMN id SET DEFAULT nextval('public.parameter_types_id_seq'::regclass);


--
-- Name: parameters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameters ALTER COLUMN id SET DEFAULT nextval('public.parameters_id_seq'::regclass);


--
-- Name: requirements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.requirements ALTER COLUMN id SET DEFAULT nextval('public.requirements_id_seq'::regclass);


--
-- Name: test_cases id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_cases ALTER COLUMN id SET DEFAULT nextval('public.test_cases_id_seq'::regclass);


--
-- Name: test_cases_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_cases_type ALTER COLUMN id SET DEFAULT nextval('public.test_cases_type_id_seq'::regclass);


--
-- Name: test_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_results ALTER COLUMN id SET DEFAULT nextval('public.test_results_id_seq'::regclass);


--
-- Name: test_values id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_values ALTER COLUMN id SET DEFAULT nextval('public.test_values_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: checkmarx checkmarx_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checkmarx
    ADD CONSTRAINT checkmarx_pkey PRIMARY KEY (cm_project_id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: group_parent_child group_parent_child_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_parent_child
    ADD CONSTRAINT group_parent_child_pkey PRIMARY KEY (id);


--
-- Name: group group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."group"
    ADD CONSTRAINT group_pkey PRIMARY KEY (id);


--
-- Name: test_results id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_results
    ADD CONSTRAINT id PRIMARY KEY (id);


--
-- Name: pipeline_phase phase_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_phase
    ADD CONSTRAINT phase_pkey PRIMARY KEY (id);


--
-- Name: pipeline_software_config pipeline_software_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_software_config
    ADD CONSTRAINT pipeline_software_config_pkey PRIMARY KEY (id);


--
-- Name: pipeline_software pipeline_software_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_software
    ADD CONSTRAINT pipeline_software_list_pkey PRIMARY KEY (id);


--
-- Name: project_plugin_relation project_plugin_relation_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_plugin_relation
    ADD CONSTRAINT project_plugin_relation_pk PRIMARY KEY (project_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: user user_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_login_key UNIQUE (login);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_id_idx ON public."user" USING btree (id);


--
-- Name: group_parent_child group_child; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_parent_child
    ADD CONSTRAINT group_child FOREIGN KEY (group_child_id) REFERENCES public."group"(id) NOT VALID;


--
-- Name: groups_has_users group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups_has_users
    ADD CONSTRAINT group_id FOREIGN KEY (group_id) REFERENCES public."group"(id);


--
-- Name: group_parent_child group_parent; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_parent_child
    ADD CONSTRAINT group_parent FOREIGN KEY (group_parent_id) REFERENCES public."group"(id) NOT VALID;


--
-- Name: pipeline_software phase_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_software
    ADD CONSTRAINT phase_id FOREIGN KEY (phase_id) REFERENCES public.pipeline_phase(id) NOT VALID;


--
-- Name: pipeline_software_config project_Id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_software_config
    ADD CONSTRAINT "project_Id" FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: files project_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: project_user_role role; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_user_role
    ADD CONSTRAINT role FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: pipeline_software_config software_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pipeline_software_config
    ADD CONSTRAINT software_id FOREIGN KEY (software_id) REFERENCES public.pipeline_software(id);


--
-- Name: project_user_role user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_user_role
    ADD CONSTRAINT "user" FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: user_plugin_relation user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_plugin_relation
    ADD CONSTRAINT "user" FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: groups_has_users user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups_has_users
    ADD CONSTRAINT "user" FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO public.roles (id,name) VALUES
(3,'Project Manager')
,(5,'Administrator')
,(1,'Engineer')
;

INSERT INTO public.roles_plugin_relation (role_id,plan_role_id) VALUES
(1,3)
,(3,4)
;

INSERT INTO public.user (name, email, phone, login, password, create_at) VALUES
('admin', 'admin@devops.org', '00000000', 'admin', '4194d1706ed1f408d5e02d672777019f4d5385c766a8c6ca8acba3167d36a7b9', '1603940945')
;

INSERT INTO public.project_user_role
(project_id, user_id, role_id)
VALUES(-1, 1, 5);

