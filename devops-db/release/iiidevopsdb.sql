--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4 (Debian 12.4-1.pgdg100+1)
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
-- Name: db_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.db_version (
    version integer NOT NULL
);


ALTER TABLE public.db_version OWNER TO postgres;

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
    project_id integer NOT NULL,
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
-- Data for Name: checkmarx; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.checkmarx (scan_id, report_id, repo_id, cm_project_id, run_at, finished_at, finished) FROM stdin;
1032241	5001	5	30965	2020-10-30 02:44:20.915619	2020-10-30 03:09:55.058901	t
1032242	-1	5	30966	2020-10-30 03:26:37.079681	\N	f
1032243	5002	5	30967	2020-10-30 06:24:39.710942	2020-10-30 06:29:55.098776	t
1032244	-1	5	30968	2020-10-30 06:53:30.762856	\N	f
1032321	5025	7	31035	2020-11-12 02:14:31.684646	2020-11-13 08:52:03.715742	t
1032245	5003	5	30969	2020-10-30 06:58:56.963959	2020-10-30 10:42:56.855401	t
1032246	-1	5	30970	2020-10-30 11:31:08.498907	\N	f
1032256	-1	5	30973	2020-11-04 01:19:23.203733	\N	f
1032257	-1	5	30974	2020-11-04 01:28:34.901242	\N	f
1032323	5023	17	31037	2020-11-12 02:44:41.014059	2020-11-20 02:07:10.947765	t
1032261	-1	16	30978	2020-11-05 09:58:22.200559	\N	f
1032348	-1	17	31059	2020-11-20 02:35:59.150557	\N	f
1032349	-1	17	31060	2020-11-20 02:45:02.202193	\N	f
1032263	-1	13	30980	2020-11-06 03:25:47.209979	\N	f
1032265	-1	13	30982	2020-11-06 06:57:08.406511	\N	f
1032269	-1	13	30986	2020-11-06 07:57:59.766795	\N	f
1032330	5026	16	31046	2020-11-13 02:51:19.706255	2020-11-25 03:23:53.608048	t
1032327	5021	5	31042	2020-11-12 10:00:38.708383	2020-11-25 03:23:59.830164	t
1032262	5007	16	30979	2020-11-05 10:14:08.495321	2020-11-06 09:15:58.191059	t
1032367	-1	5	31071	2020-11-25 03:34:29.772628	\N	f
1032326	5024	20	31040	2020-11-12 03:17:44.61107	2020-11-25 08:32:38.822324	t
1032279	-1	13	30989	2020-11-09 02:59:00.069254	\N	f
1032332	5040	7	31048	2020-11-13 09:20:41.32289	2020-11-25 08:32:49.310471	t
1032280	5010	13	30990	2020-11-09 04:39:37.053362	2020-11-10 01:40:45.335851	t
1032284	-1	13	30994	2020-11-10 02:12:55.795312	\N	f
1032285	-1	13	30995	2020-11-10 03:33:45.138998	\N	f
1032286	-1	13	30996	2020-11-10 04:11:17.09773	\N	f
1032287	-1	13	30997	2020-11-10 04:12:57.158726	\N	f
1032288	-1	13	30998	2020-11-10 04:13:11.751787	\N	f
1032289	-1	13	30999	2020-11-10 04:13:48.102656	\N	f
1032290	-1	13	31000	2020-11-10 04:13:51.954329	\N	f
1032291	-1	13	31001	2020-11-10 04:14:08.966586	\N	f
1032292	-1	13	31002	2020-11-10 04:18:05.511452	\N	f
1032293	-1	13	31003	2020-11-10 04:19:08.256284	\N	f
1032294	5012	13	31004	2020-11-10 04:23:56.563271	2020-11-10 08:03:36.989312	t
1032295	-1	13	31005	2020-11-10 08:36:54.510697	\N	f
1032296	-1	13	31006	2020-11-10 08:40:07.475081	\N	f
1032297	-1	13	31007	2020-11-10 08:44:03.334741	\N	f
1032298	-1	13	31008	2020-11-10 09:00:12.518997	\N	f
1032299	5013	13	31010	2020-11-10 09:04:47.647761	\N	f
1032300	-1	13	31011	2020-11-10 10:00:43.373187	\N	f
1032301	-1	13	31012	2020-11-10 10:04:10.888525	\N	f
1032302	-1	13	31013	2020-11-10 10:12:17.965898	\N	f
1032303	-1	17	31015	2020-11-11 01:55:34.832011	\N	f
1032306	-1	17	31019	2020-11-11 02:46:41.074402	\N	f
1032308	-1	17	31021	2020-11-11 03:06:11.716048	\N	f
1032309	-1	7	31022	2020-11-11 03:53:56.088236	\N	f
1032310	-1	17	31023	2020-11-11 03:54:39.775705	\N	f
1032258	5004	5	30975	2020-11-04 03:19:00.237263	2020-11-11 04:13:55.407024	t
1032312	-1	5	31025	2020-11-11 05:56:37.359069	\N	f
1032314	-1	5	31027	2020-11-11 06:03:13.03904	\N	f
1032311	5016	17	31024	2020-11-11 04:44:07.078672	2020-11-11 07:47:58.876412	t
1032313	5017	7	31026	2020-11-11 05:58:03.829143	2020-11-11 07:48:06.720945	t
1032322	-1	17	31036	2020-11-12 02:29:18.888288	\N	f
1032325	-1	20	31039	2020-11-12 03:09:38.182362	\N	f
1032315	5018	5	31028	2020-11-11 06:31:56.993729	2020-11-12 07:24:50.358471	t
1032270	5008	16	30987	2020-11-06 10:36:17.910627	2020-11-13 01:59:44.835987	t
1032329	5022	16	31045	2020-11-13 02:21:32.736465	2020-11-13 02:28:35.416217	t
\.


--
-- Data for Name: db_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.db_version (version) FROM stdin;
1
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.files (id, type, name, state, file, editor_id, create_at, upload_at, project_id, issue_id, version_id) FROM stdin;
\.


--
-- Data for Name: flows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.flows (id, project_id, issue_id, requirement_id, type_id, name, description, serial_id, create_at, update_at, disabled) FROM stdin;
1	6	1	1	0	test1028	test	1	2020-10-28 07:26:36.23027	2020-10-28 07:26:36.230278	f
2	14	6	2	0	設定帳號	設定帳號參數	1	2020-10-29 08:54:43.988473	2020-10-29 08:54:51.540726	f
3	30	19	3	0	設定帳號	設定帳號參數	1	2020-11-04 07:23:07.159779	2020-11-04 08:48:46.248171	t
4	30	19	3	\N	設定帳號	設定帳號參數	2	2020-11-04 08:48:46.636459	2020-11-04 08:48:46.636466	f
5	45	20	4	0	設定帳號	設定帳號參數	1	2020-11-05 08:35:53.208055	2020-11-05 08:35:53.531619	t
6	46	20	4	0	設定帳號	設定帳號參數	1	2020-11-05 08:39:28.176532	2020-11-05 08:39:28.513797	t
7	3	28	5	1	123	1234	1	2020-11-09 02:02:08.227232	2020-11-09 02:02:39.338252	t
8	55	30	6	0	設定帳號	設定帳號參數	1	2020-11-10 02:01:50.316934	2020-11-10 02:02:05.900574	t
9	61	32	7	0	設定帳號	設定帳號參數	1	2020-11-10 06:05:12.898697	2020-11-10 06:05:24.562644	t
10	63	37	8	0	設定帳號	設定帳號參數	1	2020-11-11 06:06:02.712451	2020-11-11 06:06:29.23628	t
11	75	51	9	0	設定帳號	設定帳號參數	1	2020-11-16 08:08:05.003861	2020-11-16 08:08:17.371193	t
12	61	32	7	0	test1126	test1126	2	2020-11-26 01:08:28.594563	2020-11-26 01:08:28.594578	f
\.


--
-- Data for Name: group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."group" (id, name, description, create_at, update_at) FROM stdin;
\.


--
-- Data for Name: group_parent_child; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_parent_child (id, group_parent_id, group_child_id) FROM stdin;
\.


--
-- Data for Name: groups_has_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groups_has_users (group_id, user_id) FROM stdin;
\.


--
-- Data for Name: http_method; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.http_method (id, type) FROM stdin;
\.


--
-- Data for Name: parameter_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parameter_types (id, type) FROM stdin;
1	文字
2	英數字
3	英文字
4	數字
\.


--
-- Data for Name: parameters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parameters (id, parameter_type_id, name, description, limitation, length, issue_id, create_at, update_at, disabled, project_id) FROM stdin;
1	3	test1029	test1029	0	100	1	2020-10-29 05:54:02.595988	2020-10-29 05:54:02.596001	f	6
2	4	123	777	77	0	28	2020-11-09 02:02:55.336622	2020-11-09 02:02:55.336636	f	3
3	2	test1126	test1126	0	100	32	2020-11-26 01:08:44.317092	2020-11-26 01:08:44.317106	f	61
\.


--
-- Data for Name: pipeline_phase; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pipeline_phase (id, name, description, "parent_phase_Id", is_closed) FROM stdin;
\.


--
-- Data for Name: pipeline_software; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pipeline_software (id, name, phase_id, is_closed, description) FROM stdin;
\.


--
-- Data for Name: pipeline_software_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pipeline_software_config (id, software_id, project_id, detail, sample) FROM stdin;
\.


--
-- Data for Name: project_plugin_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_plugin_relation (project_id, plan_project_id, git_repository_id, ci_project_id, ci_pipeline_id) FROM stdin;
3	1	2	c-sn6wz:p-ccrxg	p-ccrxg:p-5297g
13	4	5	c-sn6wz:p-ccrxg	p-ccrxg:p-vcbs2
22	6	7	c-sn6wz:p-ccrxg	p-ccrxg:p-9pvq9
27	8	9	c-sn6wz:p-ccrxg	p-ccrxg:p-jkjg9
44	12	13	c-sn6wz:p-ccrxg	p-ccrxg:p-bxr4l
50	15	16	c-sn6wz:p-ccrxg	p-ccrxg:p-xs5ph
53	16	17	c-sn6wz:p-ccrxg	p-ccrxg:p-pf845
59	19	20	c-sn6wz:p-ccrxg	p-ccrxg:p-mhvjb
60	20	21	c-sn6wz:p-ccrxg	p-ccrxg:p-pdhg2
61	21	22	c-sn6wz:p-ccrxg	p-ccrxg:p-wcnwd
72	23	25	c-sn6wz:p-ccrxg	p-ccrxg:p-nmrpw
73	24	26	c-sn6wz:p-ccrxg	p-ccrxg:p-lmxq2
80	26	29	c-sn6wz:p-ccrxg	p-ccrxg:p-5fqwk
\.


--
-- Data for Name: project_user_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_user_role (project_id, user_id, role_id) FROM stdin;
-1	1	5
-1	2	3
-1	4	3
-1	5	1
-1	7	1
-1	8	1
-1	10	1
-1	11	3
-1	12	1
13	7	1
13	12	1
-1	15	1
13	15	1
-1	16	1
13	16	1
13	11	3
-1	17	3
-1	18	1
3	17	3
3	18	1
13	10	1
-1	19	3
13	19	3
13	8	1
-1	20	3
-1	21	1
22	20	3
22	21	1
-1	23	3
-1	24	1
-1	26	3
27	8	1
27	26	3
-1	28	5
-1	31	3
-1	32	1
-1	33	1
-1	42	1
-1	43	3
44	43	3
44	42	1
50	11	3
50	12	1
-1	51	3
13	51	3
-1	52	3
3	52	3
53	31	3
53	33	1
53	32	1
44	52	3
59	20	3
60	4	3
61	5	1
53	52	3
59	52	3
22	52	3
59	21	1
-1	62	1
44	62	1
13	26	3
-1	64	3
-1	65	3
-1	66	1
-1	67	1
-1	68	1
-1	69	3
-1	70	3
-1	71	1
72	64	3
72	65	3
72	66	1
72	67	1
73	69	3
-1	74	3
44	74	3
72	52	3
13	52	3
61	4	3
-1	79	1
53	79	1
80	11	3
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, name, description, ssh_url, http_url, start_date, due_date, create_at, update_at, disabled, display) FROM stdin;
3	lwm2m	lwm2m	git@140.92.4.3:root/lwm2m.git	http://140.92.4.3/root/lwm2m.git	\N	\N	\N	\N	f	lwm2m
72	chipsec	提升IC晶片軟體安全品質(BSIMM)與合規技術研發計畫	git@140.92.4.3:root/chipsec.git	http://140.92.4.3/root/chipsec.git	\N	\N	\N	\N	f	提升IC晶片軟體安全品質(BSIMM)與合規技術研發計畫
50	modbus-tcp	現有3D列印雛形機台需將列印模型的GCode檔案透過USB碟人工傳遞插入機台USB界面進行列印, 所有操作都需在機台前控制面板現場操控, 因此容易造成以下問題:\n1. 切層軟體產生 GCode 檔案在複製到 USB 碟與人工傳遞過程中產生人為錯誤\n2. 列印過程(通常2小時以上)出現列印失敗與異常無法遠端即時操控停止列印\n所以在3D列印機台新版控制器中, 若硬體增加 Ethernet 界面並韌體擴充遠程控制模組程式, 將有機會在原本安裝切層軟體的PC端直接透過 Ethernet IP 網路與 3D 列印機台進行溝通, 解決上述的問題。	git@140.92.4.3:root/modbus-tcp.git	http://140.92.4.3/root/modbus-tcp.git	\N	\N	\N	\N	f	3D列印機台端遠程控制模組研究案
53	io-networks	艾陽科技煙火辨識專案	git@140.92.4.3:root/io-networks.git	http://140.92.4.3/root/io-networks.git	\N	\N	\N	\N	f	ioNetworks
73	test	vMME_for_test	git@140.92.4.3:root/test.git	http://140.92.4.3/root/test.git	\N	\N	\N	\N	f	vMME_for_test
61	pmgen-1605016883103	這是被自動更改過的描述	git@140.92.4.3:root/pmgen-1605016883103.git	http://140.92.4.3/root/pmgen-1605016883103.git	\N	\N	\N	\N	t	這是被自動更改過的專案名稱
59	image-transmitter	image transmitter for recognition core	git@140.92.4.3:root/image-transmitter.git	http://140.92.4.3/root/image-transmitter.git	\N	\N	\N	\N	f	影像傳輸模組
60	testproject1110	testproject1110	git@140.92.4.3:root/testproject1110.git	http://140.92.4.3/root/testproject1110.git	\N	\N	\N	\N	f	testproject1110
13	fy109-devops	fy109-devops FY109 環構敏捷工具平台系統	git@140.92.4.3:root/fy109-devops.git	http://140.92.4.3/root/fy109-devops.git	\N	\N	\N	\N	f	FY109 環構敏捷工具平台系統
22	recognition-core	recognition-core ( 雲端辨識核心 )	git@140.92.4.3:root/recognition-core.git	http://140.92.4.3/root/recognition-core.git	\N	\N	\N	\N	f	雲端辨識核心
44	arc-mvp-service-robot	智慧社區服務型機器人導入驗證計畫 MVP	git@140.92.4.3:root/arc-mvp-service-robot.git	http://140.92.4.3/root/arc-mvp-service-robot.git	\N	\N	\N	\N	f	智慧社區服務型機器人導入驗證計畫
80	phptest001	PHP 測試專案001	git@140.92.4.3:root/phptest001.git	http://140.92.4.3/root/phptest001.git	\N	\N	\N	\N	f	PHP 測試專案
27	uitest4hua	uitest4hua1g	git@140.92.4.3:root/uitest4hua.git	http://140.92.4.3/root/uitest4hua.git	\N	\N	\N	\N	f	uitestgg
\.


--
-- Data for Name: requirements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.requirements (id, project_id, issue_id, flow_info, create_at, update_at, disabled) FROM stdin;
1	6	1	\N	2020-10-28 07:26:36.213759	2020-10-28 07:26:36.213774	f
2	14	6	\N	2020-10-29 08:54:43.974525	2020-10-29 08:54:43.974536	f
3	30	19	\N	2020-11-04 07:23:07.146912	2020-11-04 07:23:07.146937	f
4	45	20	\N	2020-11-05 08:35:53.194339	2020-11-05 08:35:53.19435	f
5	3	28	\N	2020-11-09 02:02:08.21408	2020-11-09 02:02:08.214087	f
6	55	30	\N	2020-11-10 02:01:50.300307	2020-11-10 02:01:50.300314	f
7	61	32	\N	2020-11-10 06:05:12.884956	2020-11-10 06:05:12.884966	f
8	63	37	\N	2020-11-11 06:06:02.698054	2020-11-11 06:06:02.698065	f
9	75	51	\N	2020-11-16 08:08:04.986924	2020-11-16 08:08:04.986938	f
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name) FROM stdin;
3	Project Manager
5	Administrator
1	Engineer
\.


--
-- Data for Name: roles_plugin_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles_plugin_relation (role_id, plan_role_id) FROM stdin;
1	3
3	4
\.


--
-- Data for Name: test_cases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_cases (id, name, description, issue_id, project_id, create_at, update_at, disabled, data, type_id) FROM stdin;
1	忘記密碼	測試33333	19	2	2020-11-04 08:48:46.991905	2020-11-04 08:48:46.991921	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
2	忘記密碼	測試33333	\N	30	2020-11-04 08:48:47.415345	2020-11-04 08:48:47.415358	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
3	忘記密碼	測試33333	\N	45	2020-11-05 08:35:53.643381	2020-11-05 08:35:53.643394	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
4	忘記密碼	測試33333	20	2	2020-11-05 08:35:53.924463	2020-11-05 08:35:53.92448	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
5	忘記密碼	測試33333	\N	46	2020-11-05 08:39:28.625327	2020-11-05 08:39:28.625343	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
6	忘記密碼	測試33333	20	2	2020-11-05 08:39:28.883797	2020-11-05 08:39:28.88381	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
7	忘記密碼	測試33333	\N	55	2020-11-10 02:02:10.823769	2020-11-10 02:02:10.823785	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
8	忘記密碼	測試33333	30	2	2020-11-10 02:02:16.027773	2020-11-10 02:02:16.027786	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
9	忘記密碼	測試33333	\N	61	2020-11-10 06:05:27.82974	2020-11-10 06:05:27.829756	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
10	忘記密碼	測試33333	32	2	2020-11-10 06:05:32.510648	2020-11-10 06:05:32.510663	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
11	忘記密碼	測試33333	\N	63	2020-11-11 06:06:35.607537	2020-11-11 06:06:35.607556	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
12	忘記密碼	測試33333	37	2	2020-11-11 06:06:54.958098	2020-11-11 06:06:54.958115	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
13	忘記密碼	測試33333	\N	75	2020-11-16 08:08:21.781271	2020-11-16 08:08:21.781289	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
14	忘記密碼	測試33333	51	2	2020-11-16 08:08:27.632819	2020-11-16 08:08:27.632839	f	{"type": "API", "url": "/user/forgot", "method_id": "2", "method": "POST"}	1
\.


--
-- Data for Name: test_cases_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_cases_type (id, name) FROM stdin;
1	API
\.


--
-- Data for Name: test_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_items (id, issue_id, project_id, name, is_passed, create_at, update_at, disabled, test_case_id) FROM stdin;
\.


--
-- Data for Name: test_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_results (id, project_id, branch, total, fail, run_at) FROM stdin;
\.


--
-- Data for Name: test_values; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_values (id, type_id, key, value, location_id, test_item_id, test_case_id, issue_id, project_id, create_at, update_at, disabled) FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."user" (id, name, email, phone, login, password, create_at, update_at, disabled) FROM stdin;
31	黃友鍊	uln@iii.org.tw	(02)6607-3207	uln	a5f9f5f49ef39800f568b25cdd536f59962488c82e1808416e666e1a8a7aa937	2020-11-04 07:37:59.089948	\N	f
32	李佳謙	pioterlee@iii.org.tw	(02)6607-3213	pioterlee	b610373694bb000f1ec3a0a038d746ae7ea02e59cd2017ff4fac57233ad08e8f	2020-11-04 07:39:27.609758	\N	f
2	lwm2m	lwm2m@iii.org.tw	123456	lwm2m	7ca942a482a20a895ab926b35fb4b7f3f28da8dbbd7b9de7ef61d4f128f3cb59	2020-10-27 03:50:55.707936	\N	f
33	火致力	clhuo@iii.org.tw	(07)12345678	clhuo	8a537183a708be2c75a1c9f13e88cef8357d6b593a95c99aa124428ebc3f783e	2020-11-04 07:40:48.855716	\N	f
5	rd01	rd01@test.com	0987654321	test_rd_1	d460a96aa6b49db052ef9f1aac13d33e9a1dec525ed70547a8a49feb20fcdfb0	2020-10-28 03:04:50.240253	\N	f
4	pm01	pm01@test.com	0987654321	TEST_PM_01	d460a96aa6b49db052ef9f1aac13d33e9a1dec525ed70547a8a49feb20fcdfb0	2020-10-28 02:56:16.627314	2020-10-28 03:23:25.489269	f
1	admin	admin@devops.org	0987-654-321	admin	80d41c54a8ce6d26ae0bdd509db6b187140cae39b4b771269a0d006b0620e2d2	2020-10-27 00:50:55	2020-10-28 02:54:30.150664	f
8	jhhuang	jhhuang@iii.org.tw	2546	jhhuangrd	d460a96aa6b49db052ef9f1aac13d33e9a1dec525ed70547a8a49feb20fcdfb0	2020-10-29 03:40:59.421655	\N	f
10	周育緯	yuweichou@iii.org.tw	02-66072163	yuweichou	d460a96aa6b49db052ef9f1aac13d33e9a1dec525ed70547a8a49feb20fcdfb0	2020-10-29 05:55:39.891689	2020-10-30 03:23:30.328525	f
16	蔡仲明	romulus@iii.org.tw	02-33931589	romulus	9e4b98c1f5f9bea03f1e4cb632f4770f1842097041ac446e81c31b7bb1e3b847	2020-10-30 07:06:57.201955	2020-10-30 07:11:31.839286	f
17	郭祐暢	bryan@iii.org.tw	(02)6607-2826	bryan	9c09a6bc18a08476796ff10edfe48e6134f042504b495dcae5101ecd0fe52571	2020-11-03 04:17:18.367958	\N	f
18	黃偉倫	aaronwlhuang@iii.org.tw	(02)6607-3687	aaronwlhuang	7547d55d453dd1f9ce286b757be65d2197d40ce77f6a4e62fdb81e0f7e6da911	2020-11-03 04:18:18.16227	\N	f
11	蔡宗融(PM)	jonathan@iii.org.tw	02-66072908	jonathan	b38cfff020ee5c70fec7d197e0584cbe2201120fa5c10b32879d5e2b5b2536cf	2020-10-29 08:00:47.83683	2020-11-03 06:00:14.953302	f
19	Joseph PM	josephhuang.pm@iii.org.tw	02-66072318	josephhuang.pm	514cedc5a74404407cb25627410a3e8287d284f3da11ac4fea1725a649b9f987	2020-11-03 06:40:39.255562	\N	f
20	李柏霖	bolinli@iii.org.tw	(02)6607-2308	bolinli	cffeeef1b39b028108e34610b0d036276b060a3437476642f14f04769fb47030	2020-11-03 08:24:24.397271	\N	f
21	李柏霖(RD)	bolinli_rd@iii.org.tw	(02)6607-2308	bolinli_rd	cffeeef1b39b028108e34610b0d036276b060a3437476642f14f04769fb47030	2020-11-03 08:26:00.494026	\N	f
23	黃文謙	randyhuang@iii.org.tw	(02)6607-2223	wenchien	ea8a4f24b65f67b2039c3c4a4ab51a95f857098c1711245f98bbc53cd643f316	2020-11-04 02:32:58.539644	\N	f
24	黃文謙(RD)	randyhuang_rd@iii.org.tw	(02)6607-2223	wenchien_rd	ea8a4f24b65f67b2039c3c4a4ab51a95f857098c1711245f98bbc53cd643f316	2020-11-04 02:35:14.658092	\N	f
12	蔡宗融(RD)	jonathan.iii.tw@gmail.com	02-66072908	jonathan_rd	b38cfff020ee5c70fec7d197e0584cbe2201120fa5c10b32879d5e2b5b2536cf	2020-10-29 08:01:59.973531	2020-11-04 03:21:06.850128	f
28	am01	am01@test.com	0987-654321	test_am_1	514cedc5a74404407cb25627410a3e8287d284f3da11ac4fea1725a649b9f987	2020-11-04 06:22:33.224313	\N	f
42	陳德誠	techang@iii.org.tw	(02) 6607-3245	techang	4ee92bb00ca415037976bef99cf242499a3e627201a56c24fa6dd85bfab06253	2020-11-05 03:39:11.607211	\N	f
43	蔡宜璋	yc@iii.org.tw	(02) 6607-3244	yc	d5def3ed61bcf5cdf64add6d6d61985c007fe0c89db77c4de8777a1280c92b69	2020-11-05 03:40:23.679352	\N	f
26	jhhuangpm	jhhuangpm@gmail.com	1234	jhhuangpm	4567ae379ff121749a4917cf091d8833b2aca4e92b4e14c3410163b8452faa52	2020-11-04 02:51:37.773645	2020-11-05 07:33:11.349681	f
7	黃御哲	josephhuang@iii.org.tw	02-66072318	josephhuang	514cedc5a74404407cb25627410a3e8287d284f3da11ac4fea1725a649b9f987	2020-10-29 02:56:43.883131	2020-11-04 06:58:04.722717	f
51	周育緯(PM)	yuweichou_pm@iii.org.tw	(02)6607-2163	yuweichou_pm	52373e4998ef6c5c1e15d9e2a5037d71cda03e6b57f13a17e736b9dba3a9aa86	2020-11-06 05:49:19.466266	\N	f
52	iiidevops_pm	iiidevops_pm@iii.org.tw	02-66072163	iiidevops_pm	96e89cd6c5b5a028567335dc852fdaa8ee4a9f382a3e3ab0af4a4a7f3ea2e6ca	2020-11-09 06:38:18.982005	\N	f
62	iiidevops_rd	iiidevops_rd@iii.org.tw	(02)66072163	iiidevops_rd	96e89cd6c5b5a028567335dc852fdaa8ee4a9f382a3e3ab0af4a4a7f3ea2e6ca	2020-11-11 02:10:47.634937	\N	f
64	巫嘉勳	jaishin@iii.org.tw	(02)6607-6381	jaishin	5523b7e6713c70de8ee58c6772aee6f3802b97e0add8a011d111a83c33b0c88d	2020-11-12 02:45:27.87084	\N	f
66	顏兆陽	chaoyangyen@iii.org.tw	(02)6607-6387	chaoyangyen	905caf2744291640123e1ca3c7e7cee4f6750af208c1025afed71ad173709634	2020-11-12 02:47:51.08887	\N	f
67	高雅琪	yachikao@iii.org.tw	(02)6607-6386	yachikao	16474687b5cd7192d3bd68fe68f55a168d7b16880d2d8b3254e87a3d946d0a2e	2020-11-12 02:49:04.931947	\N	f
65	薛志祥	ut000063@iii.org.tw	(02)6607-6392	ut000063	28901309f343161c364cff4a1e3dcb0ea3d75f98e4af1485ed98967d69d87d22	2020-11-12 02:46:42.928077	2020-11-12 02:49:06.813647	f
68	黃佳威	garyhuang@iii.org.tw	(02)6607-6366	garyhuang	5fa52708b3c29eecbfd3f7df907d7d9ba2f3083422766f06c522b7de7435a59f	2020-11-12 02:50:51.30182	\N	f
69	黃佳威(PM)	garyhuang_pm@iii.org.tw	(02)6607-6366	garyhuang_pm	5fa52708b3c29eecbfd3f7df907d7d9ba2f3083422766f06c522b7de7435a59f	2020-11-12 02:53:13.835251	\N	f
70	田家瑋	emmily@iii.org.tw	(02)6607-8933	emmily	000cfecb0065d9dbaec17d4b30ece499f7d6e6a1c14094d7fefa937956f32365	2020-11-12 02:54:36.966213	\N	f
71	蔡宗達	tsungtatsai@iii.org.tw	(02)6607-8940	tsungtatsai	6f1d41ec4623e9c057ba82709262f2f974cd53e4deb824164a72465af364f08a	2020-11-12 02:56:04.626599	\N	f
74	黃紀強主任	johnnyhuang@iii.org.tw	0922-091238	johnnyhuang	3f72dec54ae688caeb69364c850628ad5d47e1f52d37359cc8897fd89d5db581	2020-11-13 07:02:36.4983	2020-11-13 08:43:48.517537	f
15	鍾興魁	rickchung@iii.org.tw	02-66072132	rickchung	122560f68902c2cc256811ff31786df51bef66d65838f5d2ce91cc95c30d9f66	2020-10-30 03:17:58.533366	2020-11-19 03:16:47.571404	f
79	盧奕叡	yirueilu@iii.org.tw	6607-6311	yirueilu	78551c2b6d0c95fce7f09471c06a90c5e3d70a2d0cb0fee8bd1abf03e0a8b040	2020-11-17 08:55:05.406759	\N	f
\.


--
-- Data for Name: user_plugin_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_plugin_relation (user_id, plan_user_id, repository_user_id) FROM stdin;
2	5	3
4	6	4
5	7	5
7	8	6
8	9	7
10	10	8
11	11	9
12	12	10
15	13	11
16	14	12
17	15	13
18	16	14
19	17	15
20	18	16
21	19	17
23	20	18
24	21	19
26	22	20
28	23	21
31	25	24
32	26	25
33	27	26
42	34	33
43	35	34
51	39	38
52	40	39
62	44	44
64	45	45
65	46	46
66	47	47
67	48	48
68	49	49
69	50	50
70	51	51
71	52	52
74	53	54
79	57	58
\.


--
-- Name: flows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.flows_id_seq', 12, true);


--
-- Name: group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_id_seq', 1, false);


--
-- Name: http_method_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.http_method_id_seq', 1, false);


--
-- Name: parameter_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parameter_types_id_seq', 4, true);


--
-- Name: parameters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parameters_id_seq', 3, true);


--
-- Name: requirements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.requirements_id_seq', 9, true);


--
-- Name: test_cases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_cases_id_seq', 14, true);


--
-- Name: test_cases_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_cases_type_id_seq', 1, true);


--
-- Name: test_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_items_id_seq', 1, false);


--
-- Name: test_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_results_id_seq', 1, false);


--
-- Name: test_values_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_values_id_seq', 1, false);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_id_seq', 80, true);


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
-- Name: project_user_role project_user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_user_role
    ADD CONSTRAINT project_user_role_pkey PRIMARY KEY (project_id, user_id, role_id);


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

