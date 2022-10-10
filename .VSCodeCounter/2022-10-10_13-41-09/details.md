# Details

Date : 2022-10-10 13:41:09

Directory /Users/nevendrean/code/elixir/live_map

Total : 99 files,  3898 codes, 698 comments, 706 blanks, all 5302 lines

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [.formatter.exs](/.formatter.exs) | Elixir | 5 | 0 | 1 | 6 |
| [README.md](/README.md) | Markdown | 135 | 0 | 41 | 176 |
| [assets/css/app.css](/assets/css/app.css) | CSS | 137 | 3 | 19 | 159 |
| [assets/css/phoenix.css](/assets/css/phoenix.css) | CSS | 85 | 9 | 8 | 102 |
| [assets/js/app.js](/assets/js/app.js) | JavaScript | 48 | 26 | 14 | 88 |
| [assets/js/fbLogin.js](/assets/js/fbLogin.js) | JavaScript | 44 | 7 | 5 | 56 |
| [assets/js/infiniteScroll.js](/assets/js/infiniteScroll.js) | JavaScript | 30 | 1 | 1 | 32 |
| [assets/js/maphook.js](/assets/js/maphook.js) | JavaScript | 246 | 44 | 40 | 330 |
| [assets/js/user.js](/assets/js/user.js) | JavaScript | 22 | 1 | 5 | 28 |
| [assets/js/user_socket.js](/assets/js/user_socket.js) | JavaScript | 15 | 46 | 7 | 68 |
| [assets/package-lock.json](/assets/package-lock.json) | JSON | 209 | 0 | 1 | 210 |
| [assets/package.json](/assets/package.json) | JSON | 9 | 0 | 1 | 10 |
| [assets/tailwind.config.js](/assets/tailwind.config.js) | JavaScript | 31 | 2 | 3 | 36 |
| [assets/vendor/topbar.js](/assets/vendor/topbar.js) | JavaScript | 145 | 7 | 6 | 158 |
| [config/config.exs](/config/config.exs) | Elixir | 46 | 20 | 13 | 79 |
| [config/dev.exs](/config/dev.exs) | Elixir | 33 | 38 | 8 | 79 |
| [config/prod.exs](/config/prod.exs) | Elixir | 3 | 43 | 4 | 50 |
| [config/runtime.exs](/config/runtime.exs) | Elixir | 34 | 42 | 10 | 86 |
| [config/test.exs](/config/test.exs) | Elixir | 15 | 10 | 6 | 31 |
| [ecto_erd.dot](/ecto_erd.dot) | Graphviz (DOT) | 11 | 0 | 2 | 13 |
| [events.sql](/events.sql) | SQL | 61 | 32 | 23 | 116 |
| [lib/live_map.ex](/lib/live_map.ex) | Elixir | 8 | 0 | 2 | 10 |
| [lib/live_map/application.ex](/lib/live_map/application.ex) | Elixir | 25 | 5 | 5 | 35 |
| [lib/live_map/changesets/new_event.ex](/lib/live_map/changesets/new_event.ex) | Elixir | 26 | 0 | 6 | 32 |
| [lib/live_map/changesets/query_picker.ex](/lib/live_map/changesets/query_picker.ex) | Elixir | 31 | 0 | 9 | 40 |
| [lib/live_map/geojson.ex](/lib/live_map/geojson.ex) | Elixir | 47 | 2 | 6 | 55 |
| [lib/live_map/postgres_types.ex](/lib/live_map/postgres_types.ex) | Elixir | 5 | 0 | 1 | 6 |
| [lib/live_map/repo.ex](/lib/live_map/repo.ex) | Elixir | 136 | 1 | 14 | 151 |
| [lib/live_map/schemas/event_participants.ex](/lib/live_map/schemas/event_participants.ex) | Elixir | 181 | 6 | 23 | 210 |
| [lib/live_map/schemas/events.ex](/lib/live_map/schemas/events.ex) | Elixir | 92 | 1 | 13 | 106 |
| [lib/live_map/schemas/users.ex](/lib/live_map/schemas/users.ex) | Elixir | 46 | 2 | 10 | 58 |
| [lib/live_map/token.ex](/lib/live_map/token.ex) | Elixir | 66 | 1 | 5 | 72 |
| [lib/live_map_mail/email.ex](/lib/live_map_mail/email.ex) | Elixir | 39 | 0 | 7 | 46 |
| [lib/live_map_mail/mailer.ex](/lib/live_map_mail/mailer.ex) | Elixir | 3 | 0 | 1 | 4 |
| [lib/live_map_mail/templates/email/confirmation.html.heex](/lib/live_map_mail/templates/email/confirmation.html.heex) | HEEx | 10 | 0 | 0 | 10 |
| [lib/live_map_mail/templates/email/demande.html.heex](/lib/live_map_mail/templates/email/demande.html.heex) | HEEx | 11 | 0 | 0 | 11 |
| [lib/live_map_web.ex](/lib/live_map_web.ex) | Elixir | 83 | 5 | 24 | 112 |
| [lib/live_map_web/channels/event_channel.ex](/lib/live_map_web/channels/event_channel.ex) | Elixir | 7 | 26 | 7 | 40 |
| [lib/live_map_web/channels/presence.ex](/lib/live_map_web/channels/presence.ex) | Elixir | 10 | 0 | 2 | 12 |
| [lib/live_map_web/channels/user_socket.ex](/lib/live_map_web/channels/user_socket.ex) | Elixir | 35 | 4 | 8 | 47 |
| [lib/live_map_web/controllers/github_auth_controller.ex](/lib/live_map_web/controllers/github_auth_controller.ex) | Elixir | 23 | 0 | 5 | 28 |
| [lib/live_map_web/controllers/google_auth_controller.ex](/lib/live_map_web/controllers/google_auth_controller.ex) | Elixir | 21 | 0 | 5 | 26 |
| [lib/live_map_web/controllers/mail_controller.ex](/lib/live_map_web/controllers/mail_controller.ex) | Elixir | 96 | 5 | 11 | 112 |
| [lib/live_map_web/controllers/page_controller.ex](/lib/live_map_web/controllers/page_controller.ex) | Elixir | 12 | 0 | 3 | 15 |
| [lib/live_map_web/controllers/welcome_controller.ex](/lib/live_map_web/controllers/welcome_controller.ex) | Elixir | 9 | 0 | 3 | 12 |
| [lib/live_map_web/endpoint.ex](/lib/live_map_web/endpoint.ex) | Elixir | 36 | 10 | 10 | 56 |
| [lib/live_map_web/gettext.ex](/lib/live_map_web/gettext.ex) | Elixir | 15 | 3 | 7 | 25 |
| [lib/live_map_web/live/forms/new_event.ex](/lib/live_map_web/live/forms/new_event.ex) | Elixir | 65 | 2 | 12 | 79 |
| [lib/live_map_web/live/forms/query_picker.ex](/lib/live_map_web/live/forms/query_picker.ex) | Elixir | 124 | 15 | 26 | 165 |
| [lib/live_map_web/live/map_comp.ex](/lib/live_map_web/live/map_comp.ex) | Elixir | 74 | 5 | 15 | 94 |
| [lib/live_map_web/live/map_live.ex](/lib/live_map_web/live/map_live.ex) | Elixir | 90 | 14 | 20 | 124 |
| [lib/live_map_web/live/participants.ex](/lib/live_map_web/live/participants.ex) | Elixir | 8 | 0 | 2 | 10 |
| [lib/live_map_web/live/tables/new_event_table.ex](/lib/live_map_web/live/tables/new_event_table.ex) | Elixir | 79 | 0 | 9 | 88 |
| [lib/live_map_web/live/tables/selected_events.ex](/lib/live_map_web/live/tables/selected_events.ex) | Elixir | 159 | 15 | 19 | 193 |
| [lib/live_map_web/router.ex](/lib/live_map_web/router.ex) | Elixir | 36 | 16 | 13 | 65 |
| [lib/live_map_web/telemetry.ex](/lib/live_map_web/telemetry.ex) | Elixir | 54 | 10 | 8 | 72 |
| [lib/live_map_web/templates/email/confirmation.html.heex](/lib/live_map_web/templates/email/confirmation.html.heex) | HEEx | 10 | 0 | 0 | 10 |
| [lib/live_map_web/templates/email/demande.html.heex](/lib/live_map_web/templates/email/demande.html.heex) | HEEx | 11 | 0 | 0 | 11 |
| [lib/live_map_web/templates/layout/app.html.heex](/lib/live_map_web/templates/layout/app.html.heex) | HEEx | 4 | 0 | 3 | 7 |
| [lib/live_map_web/templates/layout/live.html.heex](/lib/live_map_web/templates/layout/live.html.heex) | HEEx | 15 | 0 | 4 | 19 |
| [lib/live_map_web/templates/layout/root.html.heex](/lib/live_map_web/templates/layout/root.html.heex) | HEEx | 25 | 1 | 3 | 29 |
| [lib/live_map_web/templates/page/index.html.heex](/lib/live_map_web/templates/page/index.html.heex) | HEEx | 47 | 0 | 6 | 53 |
| [lib/live_map_web/templates/page/request.html.heex](/lib/live_map_web/templates/page/request.html.heex) | HEEx | 31 | 0 | 13 | 44 |
| [lib/live_map_web/templates/page/welcome.html.heex](/lib/live_map_web/templates/page/welcome.html.heex) | HEEx | 10 | 0 | 0 | 10 |
| [lib/live_map_web/templates/welcome/welcome.html.heex](/lib/live_map_web/templates/welcome/welcome.html.heex) | HEEx | 5 | 0 | 0 | 5 |
| [lib/live_map_web/views/datalist_input.ex](/lib/live_map_web/views/datalist_input.ex) | Elixir | 9 | 0 | 3 | 12 |
| [lib/live_map_web/views/demande_participate_view.ex](/lib/live_map_web/views/demande_participate_view.ex) | Elixir | 3 | 1 | 1 | 5 |
| [lib/live_map_web/views/email_view.ex](/lib/live_map_web/views/email_view.ex) | Elixir | 3 | 1 | 1 | 5 |
| [lib/live_map_web/views/error_helpers.ex](/lib/live_map_web/views/error_helpers.ex) | Elixir | 27 | 17 | 4 | 48 |
| [lib/live_map_web/views/error_view.ex](/lib/live_map_web/views/error_view.ex) | Elixir | 6 | 8 | 3 | 17 |
| [lib/live_map_web/views/github_auth_view.ex](/lib/live_map_web/views/github_auth_view.ex) | Elixir | 3 | 1 | 1 | 5 |
| [lib/live_map_web/views/google_auth_view.ex](/lib/live_map_web/views/google_auth_view.ex) | Elixir | 3 | 1 | 1 | 5 |
| [lib/live_map_web/views/layout_view.ex](/lib/live_map_web/views/layout_view.ex) | Elixir | 5 | 2 | 2 | 9 |
| [lib/live_map_web/views/page_view.ex](/lib/live_map_web/views/page_view.ex) | Elixir | 4 | 0 | 1 | 5 |
| [lib/live_map_web/views/welcome_view.ex](/lib/live_map_web/views/welcome_view.ex) | Elixir | 4 | 0 | 1 | 5 |
| [mix.exs](/mix.exs) | Elixir | 62 | 17 | 8 | 87 |
| [mix.lock](/mix.lock) | Elixir | 63 | 0 | 1 | 64 |
| [priv/repo/migrations/.formatter.exs](/priv/repo/migrations/.formatter.exs) | Elixir | 4 | 0 | 1 | 5 |
| [priv/repo/migrations/20220919184546_postgis_enum.exs](/priv/repo/migrations/20220919184546_postgis_enum.exs) | Elixir | 12 | 0 | 3 | 15 |
| [priv/repo/migrations/20220919190000_create_users.exs](/priv/repo/migrations/20220919190000_create_users.exs) | Elixir | 10 | 3 | 4 | 17 |
| [priv/repo/migrations/20220919195327_create_events.exs](/priv/repo/migrations/20220919195327_create_events.exs) | Elixir | 20 | 1 | 6 | 27 |
| [priv/repo/migrations/20220919215903_event_participants.exs](/priv/repo/migrations/20220919215903_event_participants.exs) | Elixir | 17 | 3 | 5 | 25 |
| [priv/repo/seeds.exs](/priv/repo/seeds.exs) | Elixir | 122 | 18 | 22 | 162 |
| [priv/static/images/kitesurf.svg](/priv/static/images/kitesurf.svg) | XML | 62 | 1 | 1 | 64 |
| [read.json](/read.json) | JSON | 0 | 0 | 1 | 1 |
| [test.html](/test.html) | HTML | 20 | 0 | 3 | 23 |
| [test/date_picker/date_picker_test.exs](/test/date_picker/date_picker_test.exs) | Elixir | 12 | 0 | 4 | 16 |
| [test/live_map/downwind_test.exs](/test/live_map/downwind_test.exs) | Elixir | 0 | 61 | 16 | 77 |
| [test/live_map_mail/live_map_mail_test.exs](/test/live_map_mail/live_map_mail_test.exs) | Elixir | 0 | 45 | 10 | 55 |
| [test/live_map_web/channels/event_channel_test.exs](/test/live_map_web/channels/event_channel_test.exs) | Elixir | 0 | 22 | 6 | 28 |
| [test/live_map_web/controllers/page_controller_test.exs](/test/live_map_web/controllers/page_controller_test.exs) | Elixir | 0 | 7 | 2 | 9 |
| [test/live_map_web/views/error_view_test.exs](/test/live_map_web/views/error_view_test.exs) | Elixir | 10 | 1 | 4 | 15 |
| [test/live_map_web/views/layout_view_test.exs](/test/live_map_web/views/layout_view_test.exs) | Elixir | 3 | 4 | 2 | 9 |
| [test/live_map_web/views/page_view_test.exs](/test/live_map_web/views/page_view_test.exs) | Elixir | 3 | 0 | 1 | 4 |
| [test/support/channel_case.ex](/test/support/channel_case.ex) | Elixir | 27 | 2 | 7 | 36 |
| [test/support/conn_case.ex](/test/support/conn_case.ex) | Elixir | 29 | 2 | 8 | 39 |
| [test/support/data_case.ex](/test/support/data_case.ex) | Elixir | 48 | 0 | 11 | 59 |
| [test/support/fixtures/downwind_fixtures.ex](/test/support/fixtures/downwind_fixtures.ex) | Elixir | 21 | 0 | 3 | 24 |
| [test/test_helper.exs](/test/test_helper.exs) | Elixir | 2 | 0 | 1 | 3 |

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)