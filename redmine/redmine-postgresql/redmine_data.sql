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

--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	production	2020-10-07 07:19:26.059188	2020-10-07 07:19:26.059188
\.


--
-- Data for Name: attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attachments (id, container_id, container_type, filename, disk_filename, filesize, content_type, digest, downloads, author_id, created_on, description, disk_directory) FROM stdin;
\.


--
-- Data for Name: auth_sources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_sources (id, type, name, host, port, account, account_password, base_dn, attr_login, attr_firstname, attr_lastname, attr_mail, onthefly_register, tls, filter, timeout, verify_peer) FROM stdin;
\.


--
-- Data for Name: boards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.boards (id, project_id, name, description, "position", topics_count, messages_count, last_message_id, parent_id) FROM stdin;
\.


--
-- Data for Name: changes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.changes (id, changeset_id, action, path, from_path, from_revision, revision, branch) FROM stdin;
\.


--
-- Data for Name: changeset_parents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.changeset_parents (changeset_id, parent_id) FROM stdin;
\.


--
-- Data for Name: changesets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.changesets (id, repository_id, revision, committer, committed_on, comments, commit_date, scmid, user_id) FROM stdin;
\.


--
-- Data for Name: changesets_issues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.changesets_issues (changeset_id, issue_id) FROM stdin;
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments (id, commented_type, commented_id, author_id, content, created_on, updated_on) FROM stdin;
\.


--
-- Data for Name: custom_field_enumerations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_field_enumerations (id, custom_field_id, name, active, "position") FROM stdin;
\.


--
-- Data for Name: custom_fields; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_fields (id, type, name, field_format, possible_values, regexp, min_length, max_length, is_required, is_for_all, is_filter, "position", searchable, default_value, editable, visible, multiple, format_store, description) FROM stdin;
\.


--
-- Data for Name: custom_fields_projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_fields_projects (custom_field_id, project_id) FROM stdin;
\.


--
-- Data for Name: custom_fields_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_fields_roles (custom_field_id, role_id) FROM stdin;
\.


--
-- Data for Name: custom_fields_trackers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_fields_trackers (custom_field_id, tracker_id) FROM stdin;
\.


--
-- Data for Name: custom_values; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_values (id, customized_type, customized_id, custom_field_id, value) FROM stdin;
\.


--
-- Data for Name: documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.documents (id, project_id, category_id, title, description, created_on) FROM stdin;
\.


--
-- Data for Name: email_addresses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_addresses (id, user_id, address, is_default, notify, created_on, updated_on) FROM stdin;
1	1	admin@example.net	t	t	2020-10-07 07:19:25.144358	2020-10-07 07:19:25.144358
\.


--
-- Data for Name: enabled_modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enabled_modules (id, project_id, name) FROM stdin;
\.


--
-- Data for Name: enumerations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enumerations (id, name, "position", is_default, type, active, project_id, parent_id, position_name) FROM stdin;
2	Highest	1	f	IssuePriority	t	\N	\N	lowest
3	High	2	f	IssuePriority	t	\N	\N	default
4	Medium	3	f	IssuePriority	t	\N	\N	high2
5	Low	4	f	IssuePriority	t	\N	\N	highest
\.


--
-- Data for Name: groups_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groups_users (group_id, user_id) FROM stdin;
\.


--
-- Data for Name: import_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.import_items (id, import_id, "position", obj_id, message, unique_id) FROM stdin;
\.


--
-- Data for Name: imports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.imports (id, type, user_id, filename, settings, total_items, finished, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: issue_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.issue_categories (id, project_id, name, assigned_to_id) FROM stdin;
\.


--
-- Data for Name: issue_relations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.issue_relations (id, issue_from_id, issue_to_id, relation_type, delay) FROM stdin;
\.


--
-- Data for Name: issue_statuses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.issue_statuses (id, name, is_closed, "position", default_done_ratio) FROM stdin;
1	Active	f	1	\N
2	Assigned	f	2	\N
3	Solved	f	3	\N
4	Responsed	f	4	\N
5	Finished	f	5	\N
6	Closed	t	6	\N
\.


--
-- Data for Name: issues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.issues (id, tracker_id, project_id, subject, description, due_date, category_id, status_id, assigned_to_id, priority_id, fixed_version_id, author_id, lock_version, created_on, updated_on, start_date, done_ratio, estimated_hours, parent_id, root_id, lft, rgt, is_private, closed_on) FROM stdin;
\.


--
-- Data for Name: journal_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.journal_details (id, journal_id, property, prop_key, old_value, value) FROM stdin;
\.


--
-- Data for Name: journals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.journals (id, journalized_id, journalized_type, user_id, notes, created_on, private_notes) FROM stdin;
\.


--
-- Data for Name: member_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.member_roles (id, member_id, role_id, inherited_from) FROM stdin;
\.


--
-- Data for Name: members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.members (id, user_id, project_id, created_on, mail_notification) FROM stdin;
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, board_id, parent_id, subject, content, author_id, replies_count, last_reply_id, created_on, updated_on, locked, sticky) FROM stdin;
\.


--
-- Data for Name: news; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news (id, project_id, title, summary, description, author_id, created_on, comments_count) FROM stdin;
\.


--
-- Data for Name: open_id_authentication_associations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.open_id_authentication_associations (id, issued, lifetime, handle, assoc_type, server_url, secret) FROM stdin;
\.


--
-- Data for Name: open_id_authentication_nonces; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.open_id_authentication_nonces (id, "timestamp", server_url, salt) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, name, description, homepage, is_public, parent_id, created_on, updated_on, identifier, status, lft, rgt, inherit_members, default_version_id, default_assigned_to_id) FROM stdin;
\.


--
-- Data for Name: projects_trackers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_trackers (project_id, tracker_id) FROM stdin;
\.


--
-- Data for Name: queries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.queries (id, project_id, name, filters, user_id, column_names, sort_criteria, group_by, type, visibility, options) FROM stdin;
\.


--
-- Data for Name: queries_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.queries_roles (query_id, role_id) FROM stdin;
\.


--
-- Data for Name: repositories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.repositories (id, project_id, url, login, password, root_url, type, path_encoding, log_encoding, extra_info, identifier, is_default, created_on) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, "position", assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings) FROM stdin;
1	Non member	0	t	1	---\n- :view_issues\n- :view_news\n- :view_messages\n	default	all	all	t	\N
2	Anonymous	0	t	2	---\n- :view_issues\n- :view_news\n- :view_messages\n	default	all	all	t	\N
3	Engineer	1	t	0	---\n- :view_messages\n- :add_messages\n- :edit_messages\n- :edit_own_messages\n- :delete_messages\n- :delete_own_messages\n- :manage_boards\n- :view_calendar\n- :view_documents\n- :add_documents\n- :edit_documents\n- :delete_documents\n- :view_files\n- :manage_files\n- :view_gantt\n- :view_issues\n- :add_issues\n- :edit_issues\n- :edit_own_issues\n- :copy_issues\n- :manage_issue_relations\n- :manage_subtasks\n- :set_issues_private\n- :set_own_issues_private\n- :add_issue_notes\n- :edit_issue_notes\n- :edit_own_issue_notes\n- :view_private_notes\n- :set_notes_private\n- :delete_issues\n- :view_issue_watchers\n- :add_issue_watchers\n- :delete_issue_watchers\n- :import_issues\n- :manage_categories\n- :view_news\n- :manage_news\n- :comment_news\n- :view_changesets\n- :browse_repository\n- :commit_access\n- :manage_related_issues\n- :manage_repository\n- :view_time_entries\n- :log_time\n- :edit_time_entries\n- :edit_own_time_entries\n- :manage_project_activities\n- :log_time_for_other_users\n- :import_time_entries\n- :view_wiki_pages\n- :view_wiki_edits\n- :export_wiki_pages\n- :edit_wiki_pages\n- :rename_wiki_pages\n- :delete_wiki_pages\n- :delete_wiki_pages_attachments\n- :protect_wiki_pages\n- :manage_wiki\n	default	all	all	t	--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\npermissions_all_trackers: !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n  view_issues: '1'\n  add_issues: '1'\n  edit_issues: '1'\n  add_issue_notes: '1'\n  delete_issues: '1'\npermissions_tracker_ids: !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n  view_issues: []\n  add_issues: []\n  edit_issues: []\n  add_issue_notes: []\n  delete_issues: []\n
4	Project Manager	2	t	0	---\n- :add_project\n- :edit_project\n- :close_project\n- :select_project_modules\n- :manage_members\n- :manage_versions\n- :add_subprojects\n- :manage_public_queries\n- :save_queries\n- :view_messages\n- :add_messages\n- :edit_messages\n- :edit_own_messages\n- :delete_messages\n- :delete_own_messages\n- :manage_boards\n- :view_calendar\n- :view_documents\n- :add_documents\n- :edit_documents\n- :delete_documents\n- :view_files\n- :manage_files\n- :view_gantt\n- :view_issues\n- :add_issues\n- :edit_issues\n- :edit_own_issues\n- :copy_issues\n- :manage_issue_relations\n- :manage_subtasks\n- :set_issues_private\n- :set_own_issues_private\n- :add_issue_notes\n- :edit_issue_notes\n- :edit_own_issue_notes\n- :view_private_notes\n- :set_notes_private\n- :delete_issues\n- :view_issue_watchers\n- :add_issue_watchers\n- :delete_issue_watchers\n- :import_issues\n- :manage_categories\n- :view_news\n- :manage_news\n- :comment_news\n- :view_changesets\n- :browse_repository\n- :commit_access\n- :manage_related_issues\n- :manage_repository\n- :view_time_entries\n- :log_time\n- :edit_time_entries\n- :edit_own_time_entries\n- :manage_project_activities\n- :log_time_for_other_users\n- :import_time_entries\n- :view_wiki_pages\n- :view_wiki_edits\n- :export_wiki_pages\n- :edit_wiki_pages\n- :rename_wiki_pages\n- :delete_wiki_pages\n- :delete_wiki_pages_attachments\n- :protect_wiki_pages\n- :manage_wiki\n	default	all	all	t	--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\npermissions_all_trackers: !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n  view_issues: '1'\n  add_issues: '1'\n  edit_issues: '1'\n  add_issue_notes: '1'\n  delete_issues: '1'\npermissions_tracker_ids: !ruby/hash:ActiveSupport::HashWithIndifferentAccess\n  view_issues: []\n  add_issues: []\n  edit_issues: []\n  add_issue_notes: []\n  delete_issues: []\n
\.


--
-- Data for Name: roles_managed_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles_managed_roles (role_id, managed_role_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version) FROM stdin;
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
20090214190337
20090312172426
20090312194159
20090318181151
20090323224724
20090401221305
20090401231134
20090403001910
20090406161854
20090425161243
20090503121501
20090503121505
20090503121510
20090614091200
20090704172350
20090704172355
20090704172358
20091010093521
20091017212227
20091017212457
20091017212644
20091017212938
20091017213027
20091017213113
20091017213151
20091017213228
20091017213257
20091017213332
20091017213444
20091017213536
20091017213642
20091017213716
20091017213757
20091017213835
20091017213910
20091017214015
20091017214107
20091017214136
20091017214236
20091017214308
20091017214336
20091017214406
20091017214440
20091017214519
20091017214611
20091017214644
20091017214720
20091017214750
20091025163651
20091108092559
20091114105931
20091123212029
20091205124427
20091220183509
20091220183727
20091220184736
20091225164732
20091227112908
20100129193402
20100129193813
20100221100219
20100313132032
20100313171051
20100705164950
20100819172912
20101104182107
20101107130441
20101114115114
20101114115359
20110220160626
20110223180944
20110223180953
20110224000000
20110226120112
20110226120132
20110227125750
20110228000000
20110228000100
20110401192910
20110408103312
20110412065600
20110511000000
20110902000000
20111201201315
20120115143024
20120115143100
20120115143126
20120127174243
20120205111326
20120223110929
20120301153455
20120422150750
20120705074331
20120707064544
20120714122000
20120714122100
20120714122200
20120731164049
20120930112914
20121026002032
20121026003537
20121209123234
20121209123358
20121213084931
20130110122628
20130201184705
20130202090625
20130207175206
20130207181455
20130215073721
20130215111127
20130215111141
20130217094251
20130602092539
20130710182539
20130713104233
20130713111657
20130729070143
20130911193200
20131004113137
20131005100610
20131124175346
20131210180802
20131214094309
20131215104612
20131218183023
20140228130325
20140903143914
20140920094058
20141029181752
20141029181824
20141109112308
20141122124142
20150113194759
20150113211532
20150113213922
20150113213955
20150208105930
20150510083747
20150525103953
20150526183158
20150528084820
20150528092912
20150528093249
20150725112753
20150730122707
20150730122735
20150921204850
20150921210243
20151020182334
20151020182731
20151021184614
20151021185456
20151021190616
20151024082034
20151025072118
20151031095005
20160404080304
20160416072926
20160529063352
20161001122012
20161002133421
20161010081301
20161010081528
20161010081600
20161126094932
20161220091118
20170207050700
20170302015225
20170309214320
20170320051650
20170418090031
20170419144536
20170723112801
20180501132547
20180913072918
20180923082945
20180923091603
20190315094151
20190315102101
20190510070108
20190620135549
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settings (id, name, value, updated_on) FROM stdin;
1	rest_api_enabled	1	2020-10-07 08:47:19.496909
2	jsonp_enabled	0	2020-10-07 08:47:19.506427
3	app_title	Redmine	2020-10-07 11:13:08.208567
4	welcome_text		2020-10-07 11:13:08.216412
5	per_page_options	25,50,100	2020-10-07 11:13:08.221951
6	search_results_per_page	10	2020-10-07 11:13:08.226677
7	activity_days_default	30	2020-10-07 11:13:08.231769
8	host_name	localhost:3000	2020-10-07 11:13:08.236891
9	protocol	http	2020-10-07 11:13:08.241639
10	text_formatting	markdown	2020-10-07 11:13:08.24749
11	cache_formatted_text	0	2020-10-07 11:13:08.252441
12	wiki_compression		2020-10-07 11:13:08.257018
13	feeds_limit	15	2020-10-07 11:13:08.261961
\.


--
-- Data for Name: time_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.time_entries (id, project_id, user_id, issue_id, hours, comments, activity_id, spent_on, tyear, tmonth, tweek, created_on, updated_on, author_id) FROM stdin;
\.


--
-- Data for Name: tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tokens (id, user_id, action, value, created_on, updated_on) FROM stdin;
3	1	feeds	ff87b9a4dd26eb390ba24ad08c6c6681c4b2ec4e	2020-10-08 01:50:24.064199	2020-10-08 01:50:24.064199
2	1	session	5d8027d2fed6bd6c2bffb040e2777bb640a8ce3f	2020-10-07 08:37:48.561477	2020-10-08 02:12:01.373846
\.


--
-- Data for Name: trackers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trackers (id, name, is_in_chlog, "position", is_in_roadmap, fields_bits, default_status_id, description) FROM stdin;
1	Feature	f	1	t	0	1	
2	Bug	f	2	t	0	1	
3	Document	f	3	t	0	1	
4	Research	f	4	t	0	1	
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_preferences (id, user_id, others, hide_mail, time_zone) FROM stdin;
1	1	---\n:no_self_notified: '1'\n:my_page_layout:\n  left:\n  - issuesassignedtome\n  right:\n  - issuesreportedbyme\n:my_page_settings: {}\n:comments_sorting: asc\n:warn_on_leaving_unsaved: '1'\n:textarea_font: ''\n:recently_used_projects: 3\n:history_default_tab: notes\n	t	
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, login, hashed_password, firstname, lastname, admin, status, last_login_on, language, auth_source_id, created_on, updated_on, type, identity_url, mail_notification, salt, must_change_passwd, passwd_changed_on) FROM stdin;
2				Anonymous users	f	1	\N		\N	2020-10-07 07:19:25.006306	2020-10-07 07:19:25.006306	GroupAnonymous	\N		\N	f	\N
3				Non member users	f	1	\N		\N	2020-10-07 07:19:25.058316	2020-10-07 07:19:25.058316	GroupNonMember	\N		\N	f	\N
4				Anonymous	f	0	\N		\N	2020-10-07 07:19:32.967814	2020-10-07 07:19:32.967814	AnonymousUser	\N	only_my_events	\N	f	\N
1	admin	0eb75d0319dd60f14797d9cc5d0eb4f1451a95ae	Redmine	Admin	t	1	2020-10-07 08:30:19.864014	en	\N	2020-10-07 07:19:18.33528	2020-10-07 08:38:37.488344	User	\N	all	29f928452d6e77c5ef2449e41d90ea8a	f	2020-10-07 08:37:48
\.


--
-- Data for Name: versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.versions (id, project_id, name, description, effective_date, created_on, updated_on, wiki_page_title, status, sharing) FROM stdin;
\.


--
-- Data for Name: watchers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.watchers (id, watchable_type, watchable_id, user_id) FROM stdin;
\.


--
-- Data for Name: wiki_content_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wiki_content_versions (id, wiki_content_id, page_id, author_id, data, compression, comments, updated_on, version) FROM stdin;
\.


--
-- Data for Name: wiki_contents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wiki_contents (id, page_id, author_id, text, comments, updated_on, version) FROM stdin;
\.


--
-- Data for Name: wiki_pages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wiki_pages (id, wiki_id, title, created_on, protected, parent_id) FROM stdin;
\.


--
-- Data for Name: wiki_redirects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wiki_redirects (id, wiki_id, title, redirects_to, created_on, redirects_to_wiki_id) FROM stdin;
\.


--
-- Data for Name: wikis; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wikis (id, project_id, start_page, status) FROM stdin;
\.


--
-- Data for Name: workflows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflows (id, tracker_id, old_status_id, new_status_id, role_id, assignee, author, type, field_name, rule) FROM stdin;
\.


--
-- Name: attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attachments_id_seq', 1, false);


--
-- Name: auth_sources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_sources_id_seq', 1, false);


--
-- Name: boards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.boards_id_seq', 1, false);


--
-- Name: changes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.changes_id_seq', 1, false);


--
-- Name: changesets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.changesets_id_seq', 1, false);


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_id_seq', 1, false);


--
-- Name: custom_field_enumerations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.custom_field_enumerations_id_seq', 1, false);


--
-- Name: custom_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.custom_fields_id_seq', 1, false);


--
-- Name: custom_values_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.custom_values_id_seq', 1, false);


--
-- Name: documents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.documents_id_seq', 1, false);


--
-- Name: email_addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_addresses_id_seq', 1, true);


--
-- Name: enabled_modules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enabled_modules_id_seq', 1, false);


--
-- Name: enumerations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enumerations_id_seq', 5, true);


--
-- Name: import_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.import_items_id_seq', 1, false);


--
-- Name: imports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.imports_id_seq', 1, false);


--
-- Name: issue_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.issue_categories_id_seq', 1, false);


--
-- Name: issue_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.issue_relations_id_seq', 1, false);


--
-- Name: issue_statuses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.issue_statuses_id_seq', 6, true);


--
-- Name: issues_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.issues_id_seq', 1, false);


--
-- Name: journal_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.journal_details_id_seq', 1, false);


--
-- Name: journals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.journals_id_seq', 1, false);


--
-- Name: member_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.member_roles_id_seq', 1, false);


--
-- Name: members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.members_id_seq', 1, false);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 1, false);


--
-- Name: news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_id_seq', 1, false);


--
-- Name: open_id_authentication_associations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.open_id_authentication_associations_id_seq', 1, false);


--
-- Name: open_id_authentication_nonces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.open_id_authentication_nonces_id_seq', 1, false);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_id_seq', 1, false);


--
-- Name: queries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.queries_id_seq', 1, false);


--
-- Name: repositories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.repositories_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 4, true);


--
-- Name: settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.settings_id_seq', 13, true);


--
-- Name: time_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.time_entries_id_seq', 1, false);


--
-- Name: tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tokens_id_seq', 3, true);


--
-- Name: trackers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.trackers_id_seq', 4, true);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_preferences_id_seq', 1, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 4, true);


--
-- Name: versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.versions_id_seq', 1, false);


--
-- Name: watchers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.watchers_id_seq', 1, false);


--
-- Name: wiki_content_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wiki_content_versions_id_seq', 1, false);


--
-- Name: wiki_contents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wiki_contents_id_seq', 1, false);


--
-- Name: wiki_pages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wiki_pages_id_seq', 1, false);


--
-- Name: wiki_redirects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wiki_redirects_id_seq', 1, false);


--
-- Name: wikis_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wikis_id_seq', 1, false);


--
-- Name: workflows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflows_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

