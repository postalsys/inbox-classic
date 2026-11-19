# Changelog

## [0.19.0](https://github.com/postalsys/inbox-classic/compare/v0.18.0...v0.19.0) (2026-11-19)


### Features

* **agents:** drafts an agent keeps as its own, send answers asked for later, and what agents read ([4df4810](https://github.com/postalsys/inbox-classic/commit/4df4810f60ccb10178a57d6a84aaa98b60110763))
* **agents:** MCP phase 1, sharper tools and an unsubscribe question ([9e994df](https://github.com/postalsys/inbox-classic/commit/9e994df3fcd7e6115735e56cc40d56bda212bd31))
* **agents:** programs started from a terminal, and --name for an access of its own ([f8a814a](https://github.com/postalsys/inbox-classic/commit/f8a814a7b5739b5f67e44c48b20a1ab76158d7fe))
* **agents:** the AI Agents log as data, with what agents read by the hour ([44f4153](https://github.com/postalsys/inbox-classic/commit/44f415360aa4d3e33f5b848d851c42e4034fcc8c))
* **agents:** the unsubscribe question shows each sender's address first ([785d4b0](https://github.com/postalsys/inbox-classic/commit/785d4b00245039d95d3e6002ce1ec1be64ccc27d))
* **agents:** unsubscribe asks the user, and tighter rules for sending and drafts ([beed500](https://github.com/postalsys/inbox-classic/commit/beed500d27db4040ff5db43bb5aa3948acc00a5b))
* **autoconfig:** know Gmail's and Outlook.com's own domains without a lookup ([0354bc1](https://github.com/postalsys/inbox-classic/commit/0354bc117ff99f99696ca313e27e9b3f63c4e373))
* **compose:** Windows says which AI agent wrote a draft ([531f05b](https://github.com/postalsys/inbox-classic/commit/531f05b47d99222150f8105097e7c8ce0d280a62))
* **core:** a file that ended the app turns PDF previews off ([a26ae4c](https://github.com/postalsys/inbox-classic/commit/a26ae4c693dce06c8d011b1858f7dedd8cde6a31))
* **core:** agents change many messages at once, take back their changes, and answer invitations ([a26c55c](https://github.com/postalsys/inbox-classic/commit/a26c55c736db25f39d8043ed39c03e745e61fc88))
* **core:** attachment previews drawn in Rust (render thread, limits, watchdog) ([6508759](https://github.com/postalsys/inbox-classic/commit/65087591dc4d32bb15d66087e7026af495e2d370))
* **core:** each file says its part, the bar counts encrypted and signed parts ([952f5f6](https://github.com/postalsys/inbox-classic/commit/952f5f659a49e9087d27b37c99009627f9905021))
* **core:** pe-preview, pictures and PDF pages drawn in Rust ([18ff667](https://github.com/postalsys/inbox-classic/commit/18ff667c077cb771ca90af525bdca15d24f7c555))
* **core:** previews in signed and encrypted mail, a token per part ([57ebfe3](https://github.com/postalsys/inbox-classic/commit/57ebfe3377d7ccdb6797ad2dfe29e78f6016da84))
* **core:** previews in the message view, served by token ([04b12bb](https://github.com/postalsys/inbox-classic/commit/04b12bb69ba1b4a878b5ccfb6fbe0b4c497e35f8))
* **core:** previews of a message's attachments in pe-core ([2d28ad1](https://github.com/postalsys/inbox-classic/commit/2d28ad102b1d32965a19656bce6a09bbd20b6edd))
* **ffi:** the preview C API and the reading settings ([a0544c0](https://github.com/postalsys/inbox-classic/commit/a0544c02c8c58ef77ce3073169a612421b9addb2))
* **ffi:** Undo Since and the Send question of an invitation answer ([0b8b1e5](https://github.com/postalsys/inbox-classic/commit/0b8b1e5bca9146e7e1fadc27b648a1894122c12e))
* **html:** Markdown made into a message's HTML ([e7b4fe8](https://github.com/postalsys/inbox-classic/commit/e7b4fe8f537070e5ebf21ac5bc4103665a9f55fb))
* **html:** previews of attachments after a message's text ([49990f2](https://github.com/postalsys/inbox-classic/commit/49990f24b85f97fad24e9ce182905b54762249d6))
* **i18n:** the words over what the AI Agents window's selected row of reads covers (Windows) ([b27399a](https://github.com/postalsys/inbox-classic/commit/b27399aa33796e640a0b1c7477e2dc7a59d4a494))
* **linux:** a draft an AI agent wrote says so in the compose window ([60f55a4](https://github.com/postalsys/inbox-classic/commit/60f55a465e4641c73962ac76b55be6cfcc623a12))
* **linux:** pictures and PDF files in the message ([55382e8](https://github.com/postalsys/inbox-classic/commit/55382e8ad7ee97b8732feba9c87cab7eba93cd28))
* **linux:** Show in Message, the rebuild keeping the scroll, and Print with pictures ([ca4e706](https://github.com/postalsys/inbox-classic/commit/ca4e7065ed32f619793b46d78917797b8cea8fed))
* **linux:** Sign and Encrypt in the compose window ([1bd6057](https://github.com/postalsys/inbox-classic/commit/1bd60579493fc2eb813e843c4650a749f3fecbd1))
* **linux:** the agent's unsubscribe question ([4227479](https://github.com/postalsys/inbox-classic/commit/42274792a2e1163f530781a8ea02c13202e4b35b))
* **linux:** the AI Agents log's reads, terminal programs and --name ([d14716c](https://github.com/postalsys/inbox-classic/commit/d14716c5e11823ad8d28989dec9f13f86dda6d43))
* **linux:** the lock and the part of a file in the strip ([5a20dc8](https://github.com/postalsys/inbox-classic/commit/5a20dc85b7e990b18e08319adc1fdca7d5d56670))
* **linux:** Undo Since, the report of a bulk change's Undo, and the Send question of an invitation answer ([38f93b3](https://github.com/postalsys/inbox-classic/commit/38f93b365fe92f08bbbce5e291aaac50ae6a3581))
* **mac:** a draft an AI agent wrote says so in the compose window ([72f67d9](https://github.com/postalsys/inbox-classic/commit/72f67d9d627b24bcbf772843db10850b87af4560))
* **mac:** previews in signed and encrypted mail ([0d59eb1](https://github.com/postalsys/inbox-classic/commit/0d59eb140166162624344740ae88f92d24bf77c3))
* **mac:** previews of pictures and PDF files in the message ([327d3fa](https://github.com/postalsys/inbox-classic/commit/327d3fa364748980eb5842596850fa0c77b5fcd8))
* **mac:** Show in Message, the rebuild keeping the scroll, and Print with pictures ([b0aaa3a](https://github.com/postalsys/inbox-classic/commit/b0aaa3a319d394c2db77a01477244516cd7cdcae))
* **mac:** Sign and Encrypt in the compose window ([e675a9b](https://github.com/postalsys/inbox-classic/commit/e675a9b012e4dc69e9da55c9cf5511ce8fc5bc97))
* **mac:** the agent's unsubscribe question, and the access levels wrapped ([df327cf](https://github.com/postalsys/inbox-classic/commit/df327cf0f9e6add87ae1da309dcda289d9c76c28))
* **mac:** the lock on an encrypted part's file, its part said, tested ([b721299](https://github.com/postalsys/inbox-classic/commit/b721299d4f961e3828a9059ab687cd656a41d615))
* **mac:** Undo Since in AI Agents, and the Send question of an invitation answer ([d567642](https://github.com/postalsys/inbox-classic/commit/d5676421b429d3f9a5719be59dd1a9881f559507))
* **mac:** what agents read in the AI Agents log, and programs started from a terminal ([729f1f1](https://github.com/postalsys/inbox-classic/commit/729f1f1a0afe85de5f7bf8fde73c62531b29e677))
* **mcp:** apply_to_search, undo_my_change and respond_to_invitation ([e323ad9](https://github.com/postalsys/inbox-classic/commit/e323ad91e529e9ad5eac5f1870bacd21826f6dfc))
* **mcp:** compact answers, richer rows, consistent tool names ([ed2d3d3](https://github.com/postalsys/inbox-classic/commit/ed2d3d34c06c2f074c7ddd8089ddf5a22fd5ee8a))
* **mcp:** flag colours, Watch and Ignore Conversation, folders renamed and made with their id ([10c1eb4](https://github.com/postalsys/inbox-classic/commit/10c1eb485c5bf131ba54da6a302909d817c65104))
* **mcp:** phase 2a, agent drafts, conversations, scopes and more tools ([4b38699](https://github.com/postalsys/inbox-classic/commit/4b386995eac75f0166f54042dba02e60c15eb6af))
* **mcp:** phase 2b, what agents read and the tools they were missing ([32e7189](https://github.com/postalsys/inbox-classic/commit/32e718908e92ccd95c5bd3f933db94b512fe9ace))
* **mcp:** phase 3a, bulk changes, Undo Since and invitation answers ([a3e9642](https://github.com/postalsys/inbox-classic/commit/a3e96423fb2f491bb71fb720c97254c11a5ff0e6))
* **mcp:** phase 3b, the calling program checked by the system, resources and prompts ([f42c2dd](https://github.com/postalsys/inbox-classic/commit/f42c2dd2b53ba43d61df1fa96c7a9ba8da85be56))
* **mcp:** requests side by side, conversations, scopes, changes, overview, rules, people and drafts ([bcafac4](https://github.com/postalsys/inbox-classic/commit/bcafac4a235e09e499074da51aeceb85f8a41f16))
* **mcp:** the calling program checked by the system, resources with subscriptions, and prompts ([3667d44](https://github.com/postalsys/inbox-classic/commit/3667d44473aabcccc5dfeef9c3e48e0ad9fe2e0f))
* **mcp:** what the reading pane knows, files, fenced mail text and links by domain ([97946e8](https://github.com/postalsys/inbox-classic/commit/97946e89dbba109708046b44cf63c86070286f57))
* pictures in the text drawn by the core, never the sender's bytes ([38c9fc4](https://github.com/postalsys/inbox-classic/commit/38c9fc4c75245fe7dd063beeaddf119dde09292a))
* **preview:** pictures and PDF pages shown in the message ([be53a34](https://github.com/postalsys/inbox-classic/commit/be53a34de5f01a8d0c0fdfd8f6cd10bb81912727))
* **preview:** pictures in a message's text drawn by Inbox Classic ([3583dd4](https://github.com/postalsys/inbox-classic/commit/3583dd4b084a6b73e11fe4fad224eeb60875eda4))
* **preview:** previews in signed and encrypted mail ([45f519a](https://github.com/postalsys/inbox-classic/commit/45f519ae1fe8e9f7bd8ebac4f634b2a676953d2f))
* **preview:** Show in Message, tiles and printed pictures ([dc38fb1](https://github.com/postalsys/inbox-classic/commit/dc38fb1857575eec448e09916cc89b050a7a725e))
* **preview:** Show in Message, tiles and the printout with pictures in the core ([222205e](https://github.com/postalsys/inbox-classic/commit/222205e44d2268af7c5f4a84699d9d732726324f))
* **preview:** SVG pictures drawn to a raster with resvg ([8a539fe](https://github.com/postalsys/inbox-classic/commit/8a539fe51a223a6ae9285e905e3aefe21f7da054))
* Sign and Encrypt in the compose window ([a6ed91d](https://github.com/postalsys/inbox-classic/commit/a6ed91d6d98637ee3d18102862f697adc4ddbdf5))
* **smtp:** a calendar event as nodemailer's icalEvent ([b417e9f](https://github.com/postalsys/inbox-classic/commit/b417e9ffe5bcc96096ad6337fe1fb371a40fe963))
* **store:** agents' lists of their accounts from the kept counts, and what phase 2's tools read ([dba31d7](https://github.com/postalsys/inbox-classic/commit/dba31d7897d726841b40a16fc14bf7b7076ebd50))
* **store:** changes of many messages counted in the agents' log, and invitation replies ([e844813](https://github.com/postalsys/inbox-classic/commit/e844813cd9f3f1156d1d498db73afd0cef772837))
* **store:** the search operators in one list, and a search kept to accounts ([333176d](https://github.com/postalsys/inbox-classic/commit/333176da44f339107a18d10e18fac1d11ce56c3f))
* **windows:** a view with "Preparing..." tiles is built again when its files are described ([af27bc0](https://github.com/postalsys/inbox-classic/commit/af27bc0601e7056adeb48680082e9e11087a1910))
* **windows:** previews of attachments in the reading pane ([0c31047](https://github.com/postalsys/inbox-classic/commit/0c31047bc7ce4b7c15bb6e767150b091d4e5b37a))
* **windows:** Sign and Encrypt in the compose window ([e78487b](https://github.com/postalsys/inbox-classic/commit/e78487b786a6d40a17f59b7115f7935dc7a3ffa6))
* **windows:** the agent's unsubscribe question ([487de5b](https://github.com/postalsys/inbox-classic/commit/487de5bc86b396ca4f908123ec3e3a67c67bc144))
* **windows:** what agents read under the AI Agents log, and programs started from a terminal ([b313714](https://github.com/postalsys/inbox-classic/commit/b3137145a6946c25d010a1753f4d688062a6d8d0))
* **win:** previews in signed and encrypted mail ([73cfe48](https://github.com/postalsys/inbox-classic/commit/73cfe48083c52452313d2d4ebd74618829f33da8))
* **win:** Show in Message, the rebuild keeping the scroll, and Print with pictures ([a50234d](https://github.com/postalsys/inbox-classic/commit/a50234dc954ded3f3e7b74a07dcda4488d6ad9ef))
* **win:** the lock on a file of an encrypted part, links in a part ([44afc18](https://github.com/postalsys/inbox-classic/commit/44afc1814315ea708f7a311badd11db716cd84b2))
* **win:** Undo Since in AI Agents, and the Send question of an invitation answer ([7e0ea68](https://github.com/postalsys/inbox-classic/commit/7e0ea68b7b24df1bbee6833a1f251308523263de))


### Bug Fixes

* **agents:** a ceiling on what one program can log ([f624a1f](https://github.com/postalsys/inbox-classic/commit/f624a1f2339f293978e7993aae6173f9d1512a69))
* **agents:** a draft is the user's as soon as they save it ([0a8be98](https://github.com/postalsys/inbox-classic/commit/0a8be98cb0671237cc972b2b53d0e0783a1dfcc8))
* **agents:** a draft the user sends is theirs too ([8beb12e](https://github.com/postalsys/inbox-classic/commit/8beb12ee53760c5d29673e7aa6d0a9c4ddd1aaf5))
* **agents:** an agent can not write its way past the log ([3e4337d](https://github.com/postalsys/inbox-classic/commit/3e4337d15da53e69975a5b3e9ef714711585f7f3))
* **agents:** one numbering of attachments for get_message and get_attachment ([b842d69](https://github.com/postalsys/inbox-classic/commit/b842d69c36ec08c22e0ccb99944489c2365536c8))
* **agents:** one step for the check and the question; unsubscribes count from the yes ([d68e081](https://github.com/postalsys/inbox-classic/commit/d68e08139b3655891ed3e8535a520652c54a9de9))
* **agents:** only a draft in Drafts says an agent wrote it ([7662854](https://github.com/postalsys/inbox-classic/commit/76628543e1f64b0f6862aebcb0a0c00b692d0bdf))
* **agents:** the AI Agents window counts the Last used column and a scroll bar ([280561e](https://github.com/postalsys/inbox-classic/commit/280561ebaaabb376805fd33cff4dbe2413feb6d3))
* **agents:** the Organize permission names what it now allows ([15b7b31](https://github.com/postalsys/inbox-classic/commit/15b7b31b00a0ef92ae8f2dab89b9474a6d6b36bb))
* **calendar:** an invitation reply is written from parsed values, never copied lines ([f7d34db](https://github.com/postalsys/inbox-classic/commit/f7d34db957be1f2e840f3baf829828cdcf65c3fe))
* **ci:** a new message of the catalogs alone is no change to what every app shares ([6bf8490](https://github.com/postalsys/inbox-classic/commit/6bf84903867806a1addb43d5171349bc8fb04290))
* **core:** a colour taken back only while it is the change's, and Gmail's copies counted once ([4ad5894](https://github.com/postalsys/inbox-classic/commit/4ad589483aa38b93cffd055a9775b2a2b8cec0b8))
* **core:** a large message's window hears again once its whole source is here ([85a5a7b](https://github.com/postalsys/inbox-classic/commit/85a5a7b309952efb37734ae698326963a13333f7))
* **core:** a large open's mark goes when the reader stops or never got it ([25b57fd](https://github.com/postalsys/inbox-classic/commit/25b57fdb413954c7e11ec2a0d63776d0c06ce3a7))
* **core:** a quote of pictures alone keeps a reply to encrypted mail encrypted ([4d9da12](https://github.com/postalsys/inbox-classic/commit/4d9da120b0ac664b7ce42b725e83f7e7d8cef063))
* **core:** a reply that leaves encryption off warns even when signed ([0d076f5](https://github.com/postalsys/inbox-classic/commit/0d076f5f8c27d091699a5999d1bf8482469071e9))
* **core:** a sent message is no longer offered to take back ([ead7376](https://github.com/postalsys/inbox-classic/commit/ead7376680857b56a16eaea2132e9b8c562f4d08))
* **core:** each part's pictures print right after that part's text ([939c589](https://github.com/postalsys/inbox-classic/commit/939c589b9dd040dace67cdeb4e9e6f790cc96077))
* **core:** send a click during a large download to the spare reader from the start ([11404f6](https://github.com/postalsys/inbox-classic/commit/11404f6db1657ced2c0a29d86a8ef9a500e4c5cb))
* **core:** two readers of one message each get their view ([765535c](https://github.com/postalsys/inbox-classic/commit/765535ca8893900d8abaad0a83e7aa6de85e775d))
* **help:** the switch, the recipients' pictures and the language restart ([1e80f0d](https://github.com/postalsys/inbox-classic/commit/1e80f0ddd9623b37c6e3e1c6ade6ff4a9e85dacf))
* **help:** the switch, the recipients' pictures and the language restart ([8a4a143](https://github.com/postalsys/inbox-classic/commit/8a4a143faf1530438bb4cab9abe181052f8fa8d6))
* **html:** a data: address with a tab or controls in it found as one ([8d27855](https://github.com/postalsys/inbox-classic/commit/8d27855c0d28911c47ab52464b2816bfc5c6b8c2))
* **html:** a file's name above its previews ([c7b26a4](https://github.com/postalsys/inbox-classic/commit/c7b26a4c7587173e4348bf14e1884421120a6329))
* **html:** a link in a signed or encrypted part opens in the browser ([27e0486](https://github.com/postalsys/inbox-classic/commit/27e0486b529b38b300b7a9042747675857a7ae2b))
* **html:** a preview clicked in a part's frame reaches the app ([b7c9fe6](https://github.com/postalsys/inbox-classic/commit/b7c9fe6700296ed1d7e2cf82227e94bb717e44a2))
* **html:** a printout's only data: addresses are the core's ([6a37b3d](https://github.com/postalsys/inbox-classic/commit/6a37b3deb94645868ae06fdb4b0c0ab7ffbfb730))
* **html:** no data: address hidden in a message's CSS ([4a5c2d7](https://github.com/postalsys/inbox-classic/commit/4a5c2d722eda96498bed2bea5f2ccd98d6b8bbfa))
* **html:** no picture or font of the message's own CSS reaches the web view ([b8382f2](https://github.com/postalsys/inbox-classic/commit/b8382f2bae51428cdb506a709f884f634d01ab0b))
* **i18n:** a password-protected file's tile says how to open it ([83c6726](https://github.com/postalsys/inbox-classic/commit/83c6726948c309326a6b82905767547966e8b86e))
* **i18n:** a value that chooses the words chooses them in the pseudo-language too ([2467fab](https://github.com/postalsys/inbox-classic/commit/2467fab3a5c65102de0e1e810b1ab9ce819a6f19))
* **i18n:** align translations with developer corrections ([6c44a17](https://github.com/postalsys/inbox-classic/commit/6c44a173d8daeb0383b7c294b2b04213e609abbe))
* **i18n:** clarify Dutch agent drafts and attribution ([dd6063e](https://github.com/postalsys/inbox-classic/commit/dd6063e4fe36447b603d9ae27de596c50dc67aa3))
* **i18n:** clarify French agent draft permissions ([8680ce0](https://github.com/postalsys/inbox-classic/commit/8680ce0fb7c0f5338964fff77d3da89415e0c1bf))
* **i18n:** clarify German agent draft permissions ([e3ae482](https://github.com/postalsys/inbox-classic/commit/e3ae4827aafee32d880909b0fee4f7c4dc31e086))
* **i18n:** clarify German encrypted-mail search guidance ([d74973e](https://github.com/postalsys/inbox-classic/commit/d74973e30dee9826a57402ae9969537f8b079249))
* **i18n:** clarify Hungarian agent permissions and logs ([db69820](https://github.com/postalsys/inbox-classic/commit/db6982094be19c9b193a0d6bc249a4a425f12e5d))
* **i18n:** clarify Hungarian agent permissions and logs ([e598709](https://github.com/postalsys/inbox-classic/commit/e5987097c8a9657baa18cc0c08e45d2f915a1030))
* **i18n:** clarify Hungarian encryption help and key status ([b8736e5](https://github.com/postalsys/inbox-classic/commit/b8736e5412af93951db9890b18461bafb6ba31df))
* **i18n:** clarify Hungarian mail and delivery guidance ([80b67e8](https://github.com/postalsys/inbox-classic/commit/80b67e8db524e1f0e8a7157d23953e50e5b41635))
* **i18n:** clarify Hungarian mail and delivery guidance ([05ef64c](https://github.com/postalsys/inbox-classic/commit/05ef64c82735bfd8ce143b278846e71378cb3cd1))
* **i18n:** clarify Lithuanian core mail and count messages ([7cb1430](https://github.com/postalsys/inbox-classic/commit/7cb143076cc22405c7483ec22ea4ff2665373a90))
* **i18n:** clarify Lithuanian core mail and count messages ([26cc689](https://github.com/postalsys/inbox-classic/commit/26cc6898bafb9c9250475e573bcec828006c0de7))
* **i18n:** clarify Lithuanian reader and account dialogs ([ad9aa9a](https://github.com/postalsys/inbox-classic/commit/ad9aa9ab86263074d8020e6146ab673a16575660))
* **i18n:** clarify Lithuanian reader and account dialogs ([d987243](https://github.com/postalsys/inbox-classic/commit/d98724374532eb2177164e36ed423915526b3fac))
* **i18n:** clarify Lithuanian sign-in and security messages ([41388d4](https://github.com/postalsys/inbox-classic/commit/41388d43ebb02b261d259d817fed0f10aa240b69))
* **i18n:** clarify Lithuanian sign-in and security messages ([ff48ba1](https://github.com/postalsys/inbox-classic/commit/ff48ba17ba2491dbb1bf189944dad89dee3723fa))
* **i18n:** clarify Norwegian compose encryption guidance ([3d55d48](https://github.com/postalsys/inbox-classic/commit/3d55d48d2cda626fd75ff0943b42ddab831797d9))
* **i18n:** clarify Spanish agent draft permissions ([2f8029f](https://github.com/postalsys/inbox-classic/commit/2f8029fbf17186f98909afb8fa9e124620110f03))
* **i18n:** complete four language catalog reviews ([0de42d2](https://github.com/postalsys/inbox-classic/commit/0de42d28fdd2603bb04b27dcfe9d1c547d794d25))
* **i18n:** complete Latvian, Polish, Romanian and Russian catalogs ([312e111](https://github.com/postalsys/inbox-classic/commit/312e111e6dd0909030ec22d03dd55b9064b1fae3))
* **i18n:** complete Romanian core translation review ([2ba920a](https://github.com/postalsys/inbox-classic/commit/2ba920a896aee7a500620a29b75ebf9c4cad32df))
* **i18n:** complete Russian core translation review ([cec1bdf](https://github.com/postalsys/inbox-classic/commit/cec1bdfd448248c6930cb1579a1735618291fa9e))
* **i18n:** complete six language reviews and contextual help ([b18af67](https://github.com/postalsys/inbox-classic/commit/b18af673e214c43a04033af26c3453cc87e5cf79))
* **i18n:** complete Spanish Italian and Finnish context reviews ([81e6c3e](https://github.com/postalsys/inbox-classic/commit/81e6c3e32e3396d63dce0b1c58363cc1d436f2e5))
* **i18n:** correct English originals and align translations ([bf44141](https://github.com/postalsys/inbox-classic/commit/bf44141a12811e63e7e9f3c8302345c7a16d57cc))
* **i18n:** correct wrong English claims and update tests for the new wording ([1b4ed88](https://github.com/postalsys/inbox-classic/commit/1b4ed88d3b7d03b664f43313a5a8ffdbc5e5b694))
* **i18n:** finish Croatian review and clarify search exclusions ([71df1f4](https://github.com/postalsys/inbox-classic/commit/71df1f4bc9846dd93c92f07fbc6c05efb8fbaca6))
* **i18n:** finish five language context reviews ([aeeebac](https://github.com/postalsys/inbox-classic/commit/aeeebac8f26a78b6c7aa7f869bd265a1d5c3d898))
* **i18n:** finish Lithuanian app catalog review ([e6e7362](https://github.com/postalsys/inbox-classic/commit/e6e736298c4979647c1eff7496b9c90fd00b63b4))
* **i18n:** finish Lithuanian app catalog review ([6234662](https://github.com/postalsys/inbox-classic/commit/62346621958bf8dae1588f5a8efd64db082a1262))
* **i18n:** finish Polish core and platform catalog review ([ada99a4](https://github.com/postalsys/inbox-classic/commit/ada99a40fb0e3b73ce19079dfc943ceda8afa4c3))
* **i18n:** finish remaining translation and help reviews ([a82e74e](https://github.com/postalsys/inbox-classic/commit/a82e74e57cb2a7c282c7955d60e1adfe732a9a4c))
* **i18n:** finish Romanian and Russian app translation review ([c6e754a](https://github.com/postalsys/inbox-classic/commit/c6e754ac9bdd96e3ab90d26721559296654c7b74))
* **i18n:** import active-key signature warning for review ([205bd84](https://github.com/postalsys/inbox-classic/commit/205bd846b8dd74b686f85e0af3521a363d675fd9))
* **i18n:** import PDF warning settings paths for review ([742a9dd](https://github.com/postalsys/inbox-classic/commit/742a9ddf12a622925db958e25879a9a8d8cdbfaf))
* **i18n:** integrate compose encryption drafts for review ([3552434](https://github.com/postalsys/inbox-classic/commit/3552434dbd233e36de9020ac75bbd6a35cad4b36))
* **i18n:** publish translation review progress ([37eb82f](https://github.com/postalsys/inbox-classic/commit/37eb82fab56e4daea45ce7e92bf68fc5d4e41d44))
* **i18n:** queue preview and agent unsubscribe translations ([2904d26](https://github.com/postalsys/inbox-classic/commit/2904d2681210461f9e3d9ee71fca586cb5387b31))
* **i18n:** refine agent draft attribution notices ([7283f87](https://github.com/postalsys/inbox-classic/commit/7283f871e9c4d06117fffb2bb713bdde089c6e4b))
* **i18n:** refine Brazilian Portuguese agent permissions ([b83d7bd](https://github.com/postalsys/inbox-classic/commit/b83d7bd0f64c15ba71bc064129377adf715b292f))
* **i18n:** refine Brazilian Portuguese encryption guidance ([df8e1a6](https://github.com/postalsys/inbox-classic/commit/df8e1a64cfbc9ae67f9b3d65383451a2a5309261))
* **i18n:** refine Bulgarian agent permissions and drafts ([ecd96d9](https://github.com/postalsys/inbox-classic/commit/ecd96d94bed51a9b8b152db1071e17680ed87ca4))
* **i18n:** refine Bulgarian compose wording and shortcut ([60124b4](https://github.com/postalsys/inbox-classic/commit/60124b46e3db39b5c77e2206c58ab0f2d0981a5a))
* **i18n:** refine Catalan agent permissions and drafts ([2826ceb](https://github.com/postalsys/inbox-classic/commit/2826ceb2e86308c027ee9a79016c594ce356cf36))
* **i18n:** refine Catalan compose wording and shortcuts ([0be0a9b](https://github.com/postalsys/inbox-classic/commit/0be0a9b7eba264232274b1021c2a5590f6c3603d))
* **i18n:** refine Catalan, Norwegian, Serbian and Turkish encryption guidance ([d351206](https://github.com/postalsys/inbox-classic/commit/d351206714b780383df33157fda646b60376d3d7))
* **i18n:** refine catalogs and help across eight languages ([b7e5675](https://github.com/postalsys/inbox-classic/commit/b7e56758e74aa85225d38a535fd2e2d31f4d4da0))
* **i18n:** refine Croatian agent permissions and drafts ([25e3166](https://github.com/postalsys/inbox-classic/commit/25e31664f790153f773ee165c2e58edbf85c88dd))
* **i18n:** refine Czech agent permissions and drafts ([b41a9ad](https://github.com/postalsys/inbox-classic/commit/b41a9ad5af3b45989400cc55a480cc06b667c82c))
* **i18n:** refine Czech compose wording and plural forms ([1c934ad](https://github.com/postalsys/inbox-classic/commit/1c934ad6d39fe290c60a60ad1141d22aea4a4d88))
* **i18n:** refine Danish agent permissions and drafts ([649fbec](https://github.com/postalsys/inbox-classic/commit/649fbec4531baf8e61f94a921db9a689d5b8c91a))
* **i18n:** refine Danish compose wording and track new sources ([16234be](https://github.com/postalsys/inbox-classic/commit/16234beac34c13bbadb5129b1da02b90aafff53f))
* **i18n:** refine Dutch agent unsubscribe guidance ([b16d8be](https://github.com/postalsys/inbox-classic/commit/b16d8beef42d257728a969b82238390c610ae463))
* **i18n:** refine Dutch signing and encryption guidance ([338dfcb](https://github.com/postalsys/inbox-classic/commit/338dfcb9fe78bbabe1df8281d8e17e33b4310e19))
* **i18n:** refine Dutch, Italian and Portuguese encryption guidance ([2c317eb](https://github.com/postalsys/inbox-classic/commit/2c317eb3d4966577db315bd70b74c5285c1140bf))
* **i18n:** refine encryption guidance in five more languages ([b0bdea4](https://github.com/postalsys/inbox-classic/commit/b0bdea4a20192c07eeb6892dfcd828d2398bb12e))
* **i18n:** refine Estonian agent draft guidance ([1630834](https://github.com/postalsys/inbox-classic/commit/16308348f48a24141b902128d12c37d3708bfb17))
* **i18n:** refine Estonian agent unsubscribe guidance ([7e20f17](https://github.com/postalsys/inbox-classic/commit/7e20f1780873fb14cd8734278d6e9336be62a550))
* **i18n:** refine Estonian compose wording and help ([504806f](https://github.com/postalsys/inbox-classic/commit/504806f5c78d4e7b9ab3961715ef281f98cfebf1))
* **i18n:** refine Finnish agent permissions and drafts ([f7a020e](https://github.com/postalsys/inbox-classic/commit/f7a020e02e759678405db73c941c09a6b65d8b88))
* **i18n:** refine French agent unsubscribe guidance ([cc917e3](https://github.com/postalsys/inbox-classic/commit/cc917e34c8115defc121f1ddd72e60fcedb8568f))
* **i18n:** refine French compose wording and help ([30e0a7e](https://github.com/postalsys/inbox-classic/commit/30e0a7e7dd44857d6d463fbd18a97440ab823e26))
* **i18n:** refine German agent unsubscribe guidance ([df95076](https://github.com/postalsys/inbox-classic/commit/df950763a3e4ada9b57833945b5417b9603754ee))
* **i18n:** refine Greek agent permissions and drafts ([8d72274](https://github.com/postalsys/inbox-classic/commit/8d7227495c9f5924e736737bb59245d3811beb5e))
* **i18n:** refine Greek compose wording and track Linux menu corrections ([31f89fa](https://github.com/postalsys/inbox-classic/commit/31f89fa7539803763af81854d6261152648dfcae))
* **i18n:** refine Greek compose wording and track Linux menu corrections ([cd3d00e](https://github.com/postalsys/inbox-classic/commit/cd3d00e68b40cbd8418a7aef6b11d6c919f54759))
* **i18n:** refine Hungarian platform text and getting-started help ([040b737](https://github.com/postalsys/inbox-classic/commit/040b73734a7b02c3a13391e671c5c4fa4bff30a7))
* **i18n:** refine Hungarian previews and privacy help ([802ce72](https://github.com/postalsys/inbox-classic/commit/802ce727efec6b6990aaf4cee2fdca4dab664872))
* **i18n:** refine Hungarian previews and privacy help ([c6e0b48](https://github.com/postalsys/inbox-classic/commit/c6e0b48d381b8018180141e201d3f40f3ed41cd0))
* **i18n:** refine Italian agent permissions and drafts ([b04190e](https://github.com/postalsys/inbox-classic/commit/b04190e2c5f466dc7577bc556704f6195e026062))
* **i18n:** refine Italian signing and encryption guidance ([19ef08d](https://github.com/postalsys/inbox-classic/commit/19ef08da33446a2b3265fc8f8481071651299fc2))
* **i18n:** refine Latvian account and message dialogs ([52d7e9f](https://github.com/postalsys/inbox-classic/commit/52d7e9fa6314a621f60364c76c57df51ec2e59b1))
* **i18n:** refine Latvian account and message dialogs ([f27f4af](https://github.com/postalsys/inbox-classic/commit/f27f4af26a042cda7c7bb3d9397bc91b396906fd))
* **i18n:** refine Latvian contacts and security settings ([c353c25](https://github.com/postalsys/inbox-classic/commit/c353c2577b45162ebdaeca879a19eb0e1e00e884))
* **i18n:** refine Latvian menus and compose messages ([839d2e5](https://github.com/postalsys/inbox-classic/commit/839d2e5c6d2c8559869c8b10d05a633fada86bd6))
* **i18n:** refine Latvian menus and compose messages ([ff04798](https://github.com/postalsys/inbox-classic/commit/ff0479876cdc674a00cc8cf343ae08c49f03313d))
* **i18n:** refine Latvian, Polish, Romanian and Russian translations ([232f95c](https://github.com/postalsys/inbox-classic/commit/232f95c1ce94f33e3f6c40718e43e077c5a17f8d))
* **i18n:** refine Lithuanian agent actions and invitation help ([3d583ec](https://github.com/postalsys/inbox-classic/commit/3d583ec14b542f1fdacc87e055996cae99daa6c0))
* **i18n:** refine Lithuanian agent actions and invitation help ([d3152c4](https://github.com/postalsys/inbox-classic/commit/d3152c4ce8e5c465259787760ff5718bc55b961e))
* **i18n:** refine Lithuanian agent status and permissions ([026aa6e](https://github.com/postalsys/inbox-classic/commit/026aa6ea491438ae1bb5bed883939132d5d7c2c1))
* **i18n:** refine Lithuanian menus and message status ([042d277](https://github.com/postalsys/inbox-classic/commit/042d277c18b5086b0fbe677f98b494e0daa80abe))
* **i18n:** refine Lithuanian menus and message status ([2957e15](https://github.com/postalsys/inbox-classic/commit/2957e15264bb46c224aef95fb33fb6bad6905d32))
* **i18n:** refine Lithuanian platform translations ([95883e0](https://github.com/postalsys/inbox-classic/commit/95883e087eb45c5fd8ef75f485919c187ae4cad3))
* **i18n:** refine Lithuanian platform translations ([1bf2bdb](https://github.com/postalsys/inbox-classic/commit/1bf2bdbcc938a824b50b446f194e2b6f58bafbbb))
* **i18n:** refine Lithuanian setup and preview messages ([d24f7da](https://github.com/postalsys/inbox-classic/commit/d24f7da2a7d09c181f21f65dd1167a27da13c519))
* **i18n:** refine Lithuanian setup and preview messages ([adabbb9](https://github.com/postalsys/inbox-classic/commit/adabbb9b14432ef35a37ac298cf591b987726e31))
* **i18n:** refine Norwegian Bokmål agent wording ([4495e36](https://github.com/postalsys/inbox-classic/commit/4495e36f11cacbfaa83a4dc356299239f425a1a3))
* **i18n:** refine Portuguese agent permissions and drafts ([9871048](https://github.com/postalsys/inbox-classic/commit/987104880ee9edd07c7e84c2a20248edbeb29dfc))
* **i18n:** refine Portuguese signing and encryption guidance ([06e0e62](https://github.com/postalsys/inbox-classic/commit/06e0e62ea2b61c78360024e4e31066d83f1c2bf2))
* **i18n:** refine Romanian agent permissions and help ([c3586aa](https://github.com/postalsys/inbox-classic/commit/c3586aa438593c815b50a0397fb4bab597321574))
* **i18n:** refine Romanian agent permissions and help ([8e9b051](https://github.com/postalsys/inbox-classic/commit/8e9b051c7a70f7da1a5f971c8e50c89b2f80de0e))
* **i18n:** refine Romanian Linux metadata wording ([6cccefe](https://github.com/postalsys/inbox-classic/commit/6cccefe4811fe4e5dc1fd67ecf10f3bae8aa069d))
* **i18n:** refine Russian agent permissions and help ([11fcac2](https://github.com/postalsys/inbox-classic/commit/11fcac2e4e071d9c3b279f973799c37074c7767b))
* **i18n:** refine Russian agent translations and align wording assertions ([965f86f](https://github.com/postalsys/inbox-classic/commit/965f86fd6b36cfb301aab6b5f2ed3bd3bc839e14))
* **i18n:** refine Russian contacts, settings and key ownership text ([1105709](https://github.com/postalsys/inbox-classic/commit/1105709cfc20f95aac1c61ec76cbe5704dd78693))
* **i18n:** refine Russian installer and Linux store descriptions ([860cb14](https://github.com/postalsys/inbox-classic/commit/860cb1434943c1412c5241af0b4559b81cf11f00))
* **i18n:** refine Russian platform dialogs and help navigation ([cc52b82](https://github.com/postalsys/inbox-classic/commit/cc52b82c5d8d721ed2697195cdb6c7f91af80e82))
* **i18n:** refine Serbian compose wording and plurals ([ca95afb](https://github.com/postalsys/inbox-classic/commit/ca95afb392c601cc6aafa038686a32314f33ea64))
* **i18n:** refine Serbian Latin agent permissions and drafts ([1a41327](https://github.com/postalsys/inbox-classic/commit/1a41327203fb115150d83546915e7ce8b4e0bf86))
* **i18n:** refine signature key warnings across languages ([25eff7b](https://github.com/postalsys/inbox-classic/commit/25eff7b8424258885c371bef61ac64a7dbdb5c66))
* **i18n:** refine Slovak agent permissions and help ([de5ab70](https://github.com/postalsys/inbox-classic/commit/de5ab70db0d6cd701875f21c0e52b0c466edf5c0))
* **i18n:** refine Slovak agent permissions and help ([f2abf6f](https://github.com/postalsys/inbox-classic/commit/f2abf6f1374eb11d25ffd9f23bcca06ab223229f))
* **i18n:** refine Slovenian agent permissions and help ([7b889d7](https://github.com/postalsys/inbox-classic/commit/7b889d7954b82f7d3e35ebf1ec092bb286cfd895))
* **i18n:** refine Slovenian agent permissions and help ([4674437](https://github.com/postalsys/inbox-classic/commit/4674437758752799c0455de6b7d83db02d21617d))
* **i18n:** refine Slovenian compose translations and help ([c5fd696](https://github.com/postalsys/inbox-classic/commit/c5fd6965d81199aa861cf3f110581fb0a93d6c13))
* **i18n:** refine Spanish agent unsubscribe guidance ([751059d](https://github.com/postalsys/inbox-classic/commit/751059dc3a6d91bb26b87cc522d7dd9dc48cde55))
* **i18n:** refine Spanish signing and encryption guidance ([aa0570a](https://github.com/postalsys/inbox-classic/commit/aa0570afeb742b01c32c51a5acfab0d47978c264))
* **i18n:** refine Spanish, Estonian and French encryption guidance ([abc8975](https://github.com/postalsys/inbox-classic/commit/abc89754c9548a17d9dd14db7a0dcebee9c72cc5))
* **i18n:** refine Swedish agent permissions and help ([3c6674b](https://github.com/postalsys/inbox-classic/commit/3c6674b9282fba43308f4ec725b468895f789a44))
* **i18n:** refine Swedish agent permissions and help ([67b6bc7](https://github.com/postalsys/inbox-classic/commit/67b6bc743b7be3813f4bdf5dad0710edc9c3454c))
* **i18n:** refine Swedish compose translations and help ([526cb82](https://github.com/postalsys/inbox-classic/commit/526cb821d75a44283874edf7b8a59110619548ee))
* **i18n:** refine Turkish agent permissions and drafts ([81f957d](https://github.com/postalsys/inbox-classic/commit/81f957d344101807b84cb0d6bbd111f9d3cc649c))
* **i18n:** refine Turkish compose wording and shortcut ([d46734b](https://github.com/postalsys/inbox-classic/commit/d46734b9217e3de71ae31a05ab1312de7d3bdecf))
* **i18n:** refine Ukrainian agent permissions and help ([bfff91d](https://github.com/postalsys/inbox-classic/commit/bfff91d8989ee2d81caa77afcd44144b689a2228))
* **i18n:** refine Ukrainian agent permissions and help ([0ded35c](https://github.com/postalsys/inbox-classic/commit/0ded35c33be2fa11f90743ab13d50104787b3943))
* **i18n:** refine Ukrainian compose translations and help ([5a0d866](https://github.com/postalsys/inbox-classic/commit/5a0d866eee1f333656c401a166b0d61287921781))
* **i18n:** report unsubscribe approval before requests run ([34a2cc2](https://github.com/postalsys/inbox-classic/commit/34a2cc256ab7ca29ae62593709492f05d580ccb7))
* **i18n:** review Croatian compose security wording ([9b36618](https://github.com/postalsys/inbox-classic/commit/9b3661864d77d09d470f50e3b3f47cbb4d2e3203))
* **i18n:** review Croatian compose security wording ([be976ea](https://github.com/postalsys/inbox-classic/commit/be976ea3786c15a5cf01b011ad92161c85a6c25e))
* **i18n:** review Finnish compose security wording ([016b1f8](https://github.com/postalsys/inbox-classic/commit/016b1f8f18edadd54d3f11656da3c7f141de1c04))
* **i18n:** review Finnish compose security wording ([6aa3d6d](https://github.com/postalsys/inbox-classic/commit/6aa3d6d1f0223aff66b3493ba6a9609c74ed96ee))
* **i18n:** review German compose encryption wording and help ([9986cac](https://github.com/postalsys/inbox-classic/commit/9986cac38ff21057fc54b3209d0f1702d4760fa6))
* **i18n:** review Hungarian agent permissions and help ([27a6ca3](https://github.com/postalsys/inbox-classic/commit/27a6ca391676b074f569d85991d854787feb7fc3))
* **i18n:** review Hungarian app wording and clarify Undo Send ([e33a688](https://github.com/postalsys/inbox-classic/commit/e33a688724f5838166fb21727d675b017a8b357f))
* **i18n:** review Hungarian compose and writing help ([ee2fdd7](https://github.com/postalsys/inbox-classic/commit/ee2fdd7a1bfc4faf9f5d27d519eb9163046fb9fb))
* **i18n:** review Hungarian compose and writing help ([3bc622f](https://github.com/postalsys/inbox-classic/commit/3bc622f9bd526584c2df45fcb35df92fc0e60318))
* **i18n:** review Hungarian core messages and clarify agent undo ([f90cee0](https://github.com/postalsys/inbox-classic/commit/f90cee0e84585c15344f82f9d8a53266f2a95f1d))
* **i18n:** review Latvian agent permissions and help ([f2a78e9](https://github.com/postalsys/inbox-classic/commit/f2a78e901b5f8b455b4eb8e0d6cb3a289fcf7e81))
* **i18n:** review Latvian compose and writing help ([cccdacf](https://github.com/postalsys/inbox-classic/commit/cccdacf4dfa310157da0395b69d088059f3f5b8b))
* **i18n:** review Latvian compose and writing help ([2dee8ba](https://github.com/postalsys/inbox-classic/commit/2dee8ba9e43ba8dd4ae4d642fc4a98288dfe5362))
* **i18n:** review Lithuanian agent additions and help ([443a8b7](https://github.com/postalsys/inbox-classic/commit/443a8b7edf65d3ea6679ae25c5c1936966be41ae))
* **i18n:** review Lithuanian compose and writing help ([736b1c1](https://github.com/postalsys/inbox-classic/commit/736b1c1a2e6640375c3a459c3dfda7e97a2c64a6))
* **i18n:** review Lithuanian compose and writing help ([edb0a4f](https://github.com/postalsys/inbox-classic/commit/edb0a4fddc5b9836ed8608948189ee79fb02932b))
* **i18n:** review Polish agent permissions and help ([bb6a8ab](https://github.com/postalsys/inbox-classic/commit/bb6a8abc890bce3363baf1fa02fb7f4807859b88))
* **i18n:** review Polish compose and writing help ([8733234](https://github.com/postalsys/inbox-classic/commit/8733234781c09c06947daff2162a0517a77dd04c))
* **i18n:** review Polish compose and writing help ([6951b07](https://github.com/postalsys/inbox-classic/commit/6951b075dbc4e85f536d3e6bdb9bf89b6b931481))
* **i18n:** review Polish key management and remaining shared messages ([9e851fc](https://github.com/postalsys/inbox-classic/commit/9e851fc31f54e3d6163cedb703a12848a98993f7))
* **i18n:** review Romanian accounts and action dialogs ([1ad039b](https://github.com/postalsys/inbox-classic/commit/1ad039b2feb3f637995eba5e77f5864b4c250481))
* **i18n:** review Romanian compose and writing help ([76b048f](https://github.com/postalsys/inbox-classic/commit/76b048f3f1fdbb1c101d51cd453d5d7d9024877f))
* **i18n:** review Romanian compose and writing help ([cef13da](https://github.com/postalsys/inbox-classic/commit/cef13da8b82aa90b4bb53a494bf8423c64d80e37))
* **i18n:** review Romanian menus and compose wording ([9c8785a](https://github.com/postalsys/inbox-classic/commit/9c8785ad54225da8d73cb94d3dcd18972c54773e))
* **i18n:** review Romanian platform and help labels ([0f67378](https://github.com/postalsys/inbox-classic/commit/0f673789758096f591fb0b2e2fe4e31148c442cf))
* **i18n:** review Romanian settings keys and contacts ([dce486c](https://github.com/postalsys/inbox-classic/commit/dce486c3886d4ea210a9c3173073976c62bdb9c1))
* **i18n:** review Russian compose and writing help ([0fa0963](https://github.com/postalsys/inbox-classic/commit/0fa0963dbf41fc8f8feedfb93ff9ce8821e2a4fa))
* **i18n:** review Russian compose and writing help ([2da6592](https://github.com/postalsys/inbox-classic/commit/2da6592525b05dc7b4ef3a4b70257845e814cbc9))
* **i18n:** review Slovak compose and writing help ([d80dac2](https://github.com/postalsys/inbox-classic/commit/d80dac2e7a6eb7e99340ef762e709c0417c52deb))
* **i18n:** review Slovak compose and writing help ([02a3274](https://github.com/postalsys/inbox-classic/commit/02a3274627204a7d08d2732bae5f1a7842289366))
* **i18n:** the English source issues the translation review recorded ([7916386](https://github.com/postalsys/inbox-classic/commit/7916386fcf26c01ae25319ffb716cd7442043e49))
* **i18n:** the English source issues the translation review recorded ([22e156a](https://github.com/postalsys/inbox-classic/commit/22e156ab11700d6f192bd2e6fe5951ca34576598))
* **i18n:** the pseudo-language keeps command line options as they are typed ([b669b66](https://github.com/postalsys/inbox-classic/commit/b669b661bbc4349723a877184f0ee692248caf7d))
* **linux:** a GTK icon cache race that crashed the Arch UI test ([b884d94](https://github.com/postalsys/inbox-classic/commit/b884d94b7cc961f5d7f37a490564aa4777c4f2d9))
* **linux:** a message opened in a window leaves the reading pane's view ([9fd1669](https://github.com/postalsys/inbox-classic/commit/9fd166985c1f2deca0a2424694a6c5fe26b852f2))
* **linux:** Back Up Key scrolls in a window lower than it ([11fd54d](https://github.com/postalsys/inbox-classic/commit/11fd54d06a9b249ad4c6695dd42eb0facb97acea))
* **linux:** Encryption Keys closed while a question waited ([1e147cf](https://github.com/postalsys/inbox-classic/commit/1e147cffec4a1d73be7f700f7a745b2b5836b8cb))
* **linux:** every icon of the app drawn from kept paintables ([05d676a](https://github.com/postalsys/inbox-classic/commit/05d676ab1fbf4b75296b900dc28b9f3012750d9e))
* **linux:** every icon of the app drawn from kept paintables ([3b3fbcb](https://github.com/postalsys/inbox-classic/commit/3b3fbcb83d75d454d62b3cc71a193d1bf44080d1))
* **linux:** list icons drawn from kept paintables, not looked up by name ([d3c1f14](https://github.com/postalsys/inbox-classic/commit/d3c1f14cc02ec636212b27b1e3b94b98b7931d8f))
* **linux:** no picture prints as an empty box ([2c561c1](https://github.com/postalsys/inbox-classic/commit/2c561c1c1d269c35fc169443b8d23d98d97ddd82))
* **linux:** the view built again when its Preparing files are described ([87d8def](https://github.com/postalsys/inbox-classic/commit/87d8deff12336d61434249221cf0b0cbb38653d3))
* **mac:** a printout waits for its pictures ([b83d60f](https://github.com/postalsys/inbox-classic/commit/b83d60fc2992f28fed94f64103b3a455303a7c45))
* **mac:** a view whose files were "Preparing..." is made again once they are described ([898e465](https://github.com/postalsys/inbox-classic/commit/898e4652d9cbd626cc5261288f64d3c52647909f))
* **mac:** no picture prints as an empty box ([cc85211](https://github.com/postalsys/inbox-classic/commit/cc85211e6e4e9afbc5f7fba53242fa52df1175ea))
* **mac:** no picture prints as an empty box ([551e73a](https://github.com/postalsys/inbox-classic/commit/551e73a1e63af0c631b940d020718cedcec4fd8d))
* **mac:** Return, Enter and Esc answer a question with its safe button whatever AppKit does ([162c0dd](https://github.com/postalsys/inbox-classic/commit/162c0dd22d9489061cdc195a42810d695a5672ba))
* **mac:** the compose window in front while the app is in the background ([f0a1d2c](https://github.com/postalsys/inbox-classic/commit/f0a1d2c033a47346911fe7fafde06abfea9144ef))
* **mac:** the safe answer of a question keeps Return after the alert is laid out ([e3a7607](https://github.com/postalsys/inbox-classic/commit/e3a760742e6c14bab1275db5a6af9d5ed4fe7487))
* **mcp:** contacts and unsubscribe problems checked too ([f27604d](https://github.com/postalsys/inbox-classic/commit/f27604dd00157e1a9e0039667c2e201f645ec211))
* **mcp:** links show the domain a browser opens, in every fenced field ([d47479e](https://github.com/postalsys/inbox-classic/commit/d47479e44214a8848b0ce7f3b23fa6cfc9a0dd60))
* **mcp:** no sender-written text outside the fence ([5b6349b](https://github.com/postalsys/inbox-classic/commit/5b6349b203343a6c76e88993377c78825bd7c3f2))
* **pgp:** a master key that can not be read now is never replaced ([7fa8ab7](https://github.com/postalsys/inbox-classic/commit/7fa8ab7c4c121cfac53ee79f84539f1e0f82192d))
* **pgp:** a Sender other than the From is not signed for ([c1f2f13](https://github.com/postalsys/inbox-classic/commit/c1f2f13eafd542987c073af9cf2ad266a01fe839))
* **pgp:** a Subject protected inside an encryption stays out of replies and forwards ([b39388c](https://github.com/postalsys/inbox-classic/commit/b39388cfd14726b1d34b61de45e765c572ee0dfc))
* **pgp:** background decryption runs each message inside a panic boundary ([044d027](https://github.com/postalsys/inbox-classic/commit/044d0277be29309c6ca81c6c1a9c542549baff99))
* **pgp:** only the key in use for an address signs for its sender ([9924cfe](https://github.com/postalsys/inbox-classic/commit/9924cfe7b2466b4377136480e652cfa83d0e0fc0))
* **pgp:** what the OpenPGP interoperability suite found ([b14013f](https://github.com/postalsys/inbox-classic/commit/b14013f5bfe83d0cc1ef7862510e5758d45c2ffe))
* **preview:** a preview's link opens only from its own view ([bee3098](https://github.com/postalsys/inbox-classic/commit/bee3098eae431f398d0bb4c5f3d78fdbc41aedfc))
* **preview:** a printout nobody takes gives way to newer ones ([5e8b352](https://github.com/postalsys/inbox-classic/commit/5e8b352e2cddfe9ac51a3de58b220d295972ab46))
* **preview:** an SVG shape out at millions of pixels is refused before resvg draws it ([e786800](https://github.com/postalsys/inbox-classic/commit/e7868007093f2d6afdcae8259fa296504583517b))
* **preview:** late descriptions per view, the link log only in test mode ([336c15c](https://github.com/postalsys/inbox-classic/commit/336c15ccd7e0cf81e08fa46a278a77903dec8ab8))
* **preview:** measure what hayro really reads before drawing a page ([6de514b](https://github.com/postalsys/inbox-classic/commit/6de514b5d6d1ba9452f3baf3a892aab2beb623cf))
* **preview:** refuse SVG shapes that reach millions of pixels out ([8757ab1](https://github.com/postalsys/inbox-classic/commit/8757ab1c234bf3549979c06fdca14980fd3f9b80))
* **previews:** a file not described in time is "Preparing…", then the view is built again ([d355370](https://github.com/postalsys/inbox-classic/commit/d3553703ef63970ca001f92e50e1dc60ee3d3993))
* **preview:** the PDF previews notice fills in its settings place ([7933292](https://github.com/postalsys/inbox-classic/commit/7933292597b19f89c633b4d7af3bed84a2026dc1))
* **preview:** the PDF previews notice fills in its settings place ([22bf6ca](https://github.com/postalsys/inbox-classic/commit/22bf6caba806e88492b0cff232a653715a02daf5))
* **preview:** the print page is built without previews, never cut from the shown one ([a04d903](https://github.com/postalsys/inbox-classic/commit/a04d90364b51e13ddc1580ec9190121a6e470ba7))
* **ux:** a sync in the background no longer replaces the answer to what the user did ([d94c333](https://github.com/postalsys/inbox-classic/commit/d94c333dac680757d7ddb0fc67ec881880883504))
* **win:** a linked picture keeps Copy Link, the core's pictures lose Save Image ([121ed9f](https://github.com/postalsys/inbox-classic/commit/121ed9f4edf71eb817c120871a288b350a21622c))
* **windows:** a modal window keeps its focus when it comes back in front ([8c81ec4](https://github.com/postalsys/inbox-classic/commit/8c81ec4394011d2b9abbe50366df8553447bdd70))
* **windows:** AI Agents shows what each program may do whole ([7d99440](https://github.com/postalsys/inbox-classic/commit/7d99440de3b75f2bca03fdb85b133a40b6f0fe55))
* **windows:** compile the resources again when a picture they include changes ([6e639ef](https://github.com/postalsys/inbox-classic/commit/6e639efd7f8cc9e271bf2085981efb4e48b993e4))
* **win:** Undo Since's words break a long word, and its title has no dots ([1790a50](https://github.com/postalsys/inbox-classic/commit/1790a505f68ed333878c6bfc0924f72684941415))

## [0.18.0](https://github.com/postalsys/inbox-classic/compare/v0.17.1...v0.18.0) (2026-11-15)


### Features

* ask about a forgotten attachment before sending ([a9962ef](https://github.com/postalsys/inbox-classic/commit/a9962ef4ba52070cd0fa6c2d91db29b47f42ab72))
* **core:** ask about a forgotten attachment before sending ([e712c50](https://github.com/postalsys/inbox-classic/commit/e712c50c00482be45124446054f74a90463addd7))
* **core:** drafts saved automatically and kept for a crash ([b12e49f](https://github.com/postalsys/inbox-classic/commit/b12e49ff6e4f8a1b2cd6faa58df0e97005ca1909))
* **core:** message rules ([a54fcab](https://github.com/postalsys/inbox-classic/commit/a54fcab18af74a7027b2cb1efaec382595028555))
* **core:** message rules that sort the new mail of an Inbox ([ab7121d](https://github.com/postalsys/inbox-classic/commit/ab7121d706dceb649874abdcec1b706f3feec897))
* **core:** messages for a dark window ([bb97844](https://github.com/postalsys/inbox-classic/commit/bb9784412a942cea2b53de193f520a0e9fa09044))
* **core:** send from an account's other addresses ([daabe80](https://github.com/postalsys/inbox-classic/commit/daabe809ea9e7116bb9719b1d59e091e527bd7a1))
* **core:** the commands and folders of the Message Rules windows ([5fc72dd](https://github.com/postalsys/inbox-classic/commit/5fc72dd704b176692adabe724dc59fa0b4e54e6f))
* **core:** the Flagged folder, the flagged messages of every account ([aab31e3](https://github.com/postalsys/inbox-classic/commit/aab31e3ebfe3cbf91ca0b69e3cdd272872c1b6ee))
* **core:** Undo Send, a message sent waits in the Outbox to be taken back ([ab618ed](https://github.com/postalsys/inbox-classic/commit/ab618edd3f82963f40ddb237f14711951b9b205b))
* **core:** View &gt; Text Size, five sizes for reading and writing ([b952c85](https://github.com/postalsys/inbox-classic/commit/b952c85254f02fa71a84997fb49e4c8e3c37aecc))
* drafts saved automatically, and opened again after a crash ([df5a431](https://github.com/postalsys/inbox-classic/commit/df5a431fff689e1c1e6effab4389701c4311158d))
* **i18n:** Message Rules' words ([0b9ba93](https://github.com/postalsys/inbox-classic/commit/0b9ba937c06ce19ccd53318d5267e78fb2070592))
* **i18n:** Text Size's words ([6b06e59](https://github.com/postalsys/inbox-classic/commit/6b06e59a85a571885ba91b85ef200ecb414e871a))
* **i18n:** the dark messages setting's words ([813c5e2](https://github.com/postalsys/inbox-classic/commit/813c5e2aaa92cb078c93a4e0cddbdea18f699399))
* **i18n:** the Flagged folder's name ([262f3db](https://github.com/postalsys/inbox-classic/commit/262f3db5586140a5ddc66fe6f47bcd87cf4c1b44))
* **i18n:** the forgotten attachment's words ([70ad1cc](https://github.com/postalsys/inbox-classic/commit/70ad1ccf3acaf3c53c3549be669fe491cc55e85a))
* **i18n:** the other addresses' words ([fb64d96](https://github.com/postalsys/inbox-classic/commit/fb64d96a2ee28e414d5c5a8f34d170fced47b840))
* **i18n:** the restored message's words ([2e514c7](https://github.com/postalsys/inbox-classic/commit/2e514c727aada030986042000b1c97184b5ba766))
* **i18n:** the words of message rules' refusals ([34786a6](https://github.com/postalsys/inbox-classic/commit/34786a6fccc24e9cc29b51fe9fd4f0c1a4e47ab6))
* **i18n:** Undo Send's words ([5eaf93d](https://github.com/postalsys/inbox-classic/commit/5eaf93d6a111dd4710d3eeaa4e9e3254326d53e2))
* **linux:** ask about a forgotten attachment before sending ([03b2910](https://github.com/postalsys/inbox-classic/commit/03b291047aae021ecdf24ee9d8d5724f348b17ef))
* **linux:** drafts saved automatically, restored after a crash ([f44eb86](https://github.com/postalsys/inbox-classic/commit/f44eb86f5f4294b7094a7d83f5f8dd569929badb))
* **linux:** Flagged at the top of the folder list ([01fc997](https://github.com/postalsys/inbox-classic/commit/01fc99726cd87e29db1fc9316f12ab4378785df3))
* **linux:** Message Rules and the rule editor ([5f4fda8](https://github.com/postalsys/inbox-classic/commit/5f4fda8460c677db9e3eda8a71bf85744887bb63))
* **linux:** messages in dark mode, and the setting to turn it off ([f10334b](https://github.com/postalsys/inbox-classic/commit/f10334b7e4c6876f22129efe4a4e04a845283cbd))
* **linux:** other addresses in Account Properties and the From list ([5faafd0](https://github.com/postalsys/inbox-classic/commit/5faafd07d8e7e5090077684d20a83a1d4774427a))
* **linux:** Undo Send in the status bar, Edit &gt; Undo and Preferences ([9355452](https://github.com/postalsys/inbox-classic/commit/93554523feddc6991304590103ba25ba7401e645))
* **linux:** View &gt; Text Size for the reading pane, message windows and the editor ([f54f572](https://github.com/postalsys/inbox-classic/commit/f54f572849f2c7035abc3b8f55320d43abd8b6f5))
* **mac:** ask about a forgotten attachment before sending ([0124aa5](https://github.com/postalsys/inbox-classic/commit/0124aa5630c5dbe1a3191098e0f543c53d06c9a7))
* **mac:** drafts saved automatically, restored after a crash ([24f43d2](https://github.com/postalsys/inbox-classic/commit/24f43d28277afb33ce32376d2b6a334d213f278a))
* **mac:** Flagged at the top of the folder list ([2043978](https://github.com/postalsys/inbox-classic/commit/2043978f77dae04d669f15966dbeb47b41a42fed))
* **mac:** Message Rules and the rule editor ([156bedb](https://github.com/postalsys/inbox-classic/commit/156bedb73462290b94d91188c7ffc636c2ad372f))
* **mac:** messages in dark mode, and the setting to turn it off ([b696a52](https://github.com/postalsys/inbox-classic/commit/b696a5235b2fa498bde4f91c87aba656fb9f576c))
* **mac:** other addresses in Account Properties and the From list ([09f6ed8](https://github.com/postalsys/inbox-classic/commit/09f6ed852e496a51f4c197f1f89ad88de9c4a4c4))
* **mac:** Undo Send in the status bar, Edit &gt; Undo and Settings ([b9f1e6b](https://github.com/postalsys/inbox-classic/commit/b9f1e6b712ffbcc82729a64da94e63d6753aadb3))
* **mac:** View &gt; Text Size for the reading pane, message windows and the editor ([d651d90](https://github.com/postalsys/inbox-classic/commit/d651d9030d66f17efd8211b6ee9f4e9e787ff24c))
* Message Rules windows ([22aedcc](https://github.com/postalsys/inbox-classic/commit/22aedcced7e6326cbd2bb59e04f9d3cc31351474))
* messages in dark mode on the Mac and Linux ([360c8d7](https://github.com/postalsys/inbox-classic/commit/360c8d7d3f10b00a0b9b03e442e91fc52b2e5cec))
* send from another address ([3347d2b](https://github.com/postalsys/inbox-classic/commit/3347d2b184af1e0a07c78ac4673afe3a21c05dde))
* the Flagged folder ([b75575f](https://github.com/postalsys/inbox-classic/commit/b75575fce782af7be4f0165cd28ffc150a3be424))
* Undo Send ([1ad7b6b](https://github.com/postalsys/inbox-classic/commit/1ad7b6b2d1455d9ed9caae7bfe06032d4c469fc1))
* View &gt; Text Size ([9ec35e5](https://github.com/postalsys/inbox-classic/commit/9ec35e595e098b1d04e83bbe684394a3bd6d232f))
* **windows:** ask about a forgotten attachment before sending ([44531ef](https://github.com/postalsys/inbox-classic/commit/44531efe1a0c9e1591f8f2de343e5cf3efb80250))
* **windows:** drafts saved automatically, restored after a crash ([301d99d](https://github.com/postalsys/inbox-classic/commit/301d99d318c39d014ab12f357ccf56c350aa08d4))
* **windows:** Flagged at the top of the folder list ([3916b12](https://github.com/postalsys/inbox-classic/commit/3916b126fb30f7381265f986df7fb98e43966b09))
* **windows:** Message Rules and the rule editor ([9db0b1d](https://github.com/postalsys/inbox-classic/commit/9db0b1df2e8e76ac2ea429b2ed0a9e8543667b20))
* **windows:** other addresses in Account Properties and the From list ([0c71a34](https://github.com/postalsys/inbox-classic/commit/0c71a34bac819078bddf0f5c1e5494e5e98531bd))
* **windows:** Undo Send in the status bar, Edit &gt; Undo and Options ([d97907f](https://github.com/postalsys/inbox-classic/commit/d97907fe554f9338f924e559c9c14e08ae7325e3))
* **windows:** View &gt; Text Size for the reading pane, message windows and the editor ([2d117ed](https://github.com/postalsys/inbox-classic/commit/2d117ed9ccd3aaebe5a6fe8363057cd062a311e5))


### Bug Fixes

* **i18n:** no review mark inside a message of several lines ([4112de3](https://github.com/postalsys/inbox-classic/commit/4112de3a790fff00520bb9b8dc0a0a7ec73dc384))
* **i18n:** the new features' words reviewed before 0.18.0 ([dc41d0a](https://github.com/postalsys/inbox-classic/commit/dc41d0a6e6045fadcec30b1689e430eb350506c3))
* **i18n:** the new features' words reviewed in every language ([b19a895](https://github.com/postalsys/inbox-classic/commit/b19a8950c14a85451386005ff1922982fc208485))
* **linux:** an empty Outbox says so after it was filled once ([7147ea2](https://github.com/postalsys/inbox-classic/commit/7147ea26819fb5a3c6eb0757fbd139a10fae2b3f))
* **linux:** the app icon in Omarchy's app grid and dock ([3fe1018](https://github.com/postalsys/inbox-classic/commit/3fe10185ca51d7dc8d320def5dd40a77a6b4cbdb))
* **linux:** the app icon in Omarchy's app grid and dock ([8a50670](https://github.com/postalsys/inbox-classic/commit/8a50670a49a90a8c4b7f16ba0f0ab56de32c9cd8))
* **linux:** the empty Message Rules list says so, its text no longer removed with the rows ([ac46f12](https://github.com/postalsys/inbox-classic/commit/ac46f126a862a1b73b0f2dc4dbc205c12f327446))
* **linux:** View &gt; Text Size's label, which the submenu asked for and did not have ([0ddf408](https://github.com/postalsys/inbox-classic/commit/0ddf4080362aba4386d7c0246641671e5b3f314f))
* **ux:** Linux highlights Go Back, the safe answer, when a file seems forgotten ([2ba3ed0](https://github.com/postalsys/inbox-classic/commit/2ba3ed04af7d05b9d2b6695c7b85970a39b78719))
* **ux:** the empty Message Rules list's text in its middle on Linux ([098110f](https://github.com/postalsys/inbox-classic/commit/098110f7a0edb5182759da5f410213811f922677))

## [0.17.1](https://github.com/postalsys/inbox-classic/compare/v0.17.0...v0.17.1) (2026-11-14)


### Bug Fixes

* **i18n:** clearer wording in English, German, Estonian, Spanish and French ([60196fd](https://github.com/postalsys/inbox-classic/commit/60196fd128e4ed44b23406d41dca891c3e181550))
* **i18n:** clearer wording, release 0.17.1 ([9abf95c](https://github.com/postalsys/inbox-classic/commit/9abf95c17bc16f96c68c2a2a7c96407f13f504f6))

## [0.17.0](https://github.com/postalsys/inbox-classic/compare/v0.16.0...v0.17.0) (2026-11-14)


### Features

* **linux:** the watch and ignore marks in the Columns rows ([c97ae83](https://github.com/postalsys/inbox-classic/commit/c97ae834a88dceea6b1e7030e11c5599c9e190cc))
* **windows:** the sort arrow, a Folders toolbar button and a smallest window ([eaf1393](https://github.com/postalsys/inbox-classic/commit/eaf139371ff51bff5820175473b7ef793c0619c0))


### Bug Fixes

* column layout follow-ups (sort arrow, Folders button, Linux watch mark) ([f6f2992](https://github.com/postalsys/inbox-classic/commit/f6f299221cac0f7262401a70cb3d658e607c7008))

## [0.16.0](https://github.com/postalsys/inbox-classic/compare/v0.15.0...v0.16.0) (2026-11-13)


### Features

* contacts' pictures (step 5) ([8453c7f](https://github.com/postalsys/inbox-classic/commit/8453c7fb696c3d2e236245d5d71071e2637c8a9e))
* **core:** contacts' pictures ([9b3743e](https://github.com/postalsys/inbox-classic/commit/9b3743e4348ea96e3c9d4f428530815062d630ae))
* **core:** pe_initials for the windows' own pictures of a person ([76a4823](https://github.com/postalsys/inbox-classic/commit/76a4823b799932806049158c31460b56aae962ce))
* **core:** the column layout's rules, commands and words ([9ede280](https://github.com/postalsys/inbox-classic/commit/9ede2809978e82bf5f671d82d6f6fb40771fb67b))
* **core:** the first words of each message (step 2 of the column layout) ([fb59705](https://github.com/postalsys/inbox-classic/commit/fb5970570fb3251b0c9c96b22091af432145b52c))
* **core:** the first words of each message, for the list's rows of several lines ([c41acc6](https://github.com/postalsys/inbox-classic/commit/c41acc6eafe5c6f3fcf2d2cf71c06b884259118f))
* **core:** the folder_list command, a Ctrl modifier for Mac keys ([f887208](https://github.com/postalsys/inbox-classic/commit/f8872082aa5551571746dda8ea9ac6ec1c5d94dd))
* **core:** the senders' pictures of the message list ([b6a1b19](https://github.com/postalsys/inbox-classic/commit/b6a1b194eab8ab0af3c22dc9bca1252dec155ed0))
* **core:** the UI tests may serve a brand logo from the loopback address ([cd277ee](https://github.com/postalsys/inbox-classic/commit/cd277eebf3836038eeb98cfc4434069117b36497))
* hide the folder list (View &gt; Folder List) ([2baea41](https://github.com/postalsys/inbox-classic/commit/2baea41f18e19a30a3c7b4387c8dcd540be96003))
* **i18n:** the folder list's words in German, Estonian, Spanish and French ([8a5b060](https://github.com/postalsys/inbox-classic/commit/8a5b060fe1253a3f5965d5f69e824ffe5d719212))
* **i18n:** the list pictures setting's words ([9fc33b3](https://github.com/postalsys/inbox-classic/commit/9fc33b332779c3395cbbdce4259f58255d96cfc6))
* **linux:** a contact's picture in Contact Properties, the list and the reading pane ([155996f](https://github.com/postalsys/inbox-classic/commit/155996fe1161662e5a8218380be1a0f8688f4635))
* **linux:** senders' pictures in the column layout ([0a4128b](https://github.com/postalsys/inbox-classic/commit/0a4128b9441cbbacc7a59de5861e5803cd2a51bc))
* **linux:** the column layout, View &gt; Layout and Sort By ([20ca9e3](https://github.com/postalsys/inbox-classic/commit/20ca9e3bf363650c54158ccbb37a54b9ca5942b4))
* **linux:** View &gt; Folder List and the sidebar button ([bd0b6f1](https://github.com/postalsys/inbox-classic/commit/bd0b6f1463548f1c4d9fb9135e5c3a8d78723420))
* **mac:** a contact's picture in Contact Properties, the list and the reading pane ([2fcf565](https://github.com/postalsys/inbox-classic/commit/2fcf56551529253ebd9e043dc6ee1fc6cc23492d))
* **mac:** senders' pictures in the column layout ([225316d](https://github.com/postalsys/inbox-classic/commit/225316df601f083fc5d9d0e925a4b2c1d5e7f7f7))
* **mac:** the column layout, View &gt; Layout and Sort By ([3692c3b](https://github.com/postalsys/inbox-classic/commit/3692c3bd77640203d2d0c00c281dc24a3781a564))
* **mac:** View &gt; Folder List and the sidebar button ([4c2b7e2](https://github.com/postalsys/inbox-classic/commit/4c2b7e2b005da171740856ab2fa4ba125470ed6f))
* senders' pictures in the message list (step 4) ([091aeb5](https://github.com/postalsys/inbox-classic/commit/091aeb5088b481f660766331d518cc4d9e6ba2ec))
* the column layout (step 3) ([9a26236](https://github.com/postalsys/inbox-classic/commit/9a2623675ee3e4d65be3844aa7f2b46bc768cad5))
* **windows:** a contact's picture in Contact Properties, the list and the reading pane ([34da592](https://github.com/postalsys/inbox-classic/commit/34da59218b4d172fc8bcb94ec1ae11faa26755c4))
* **windows:** senders' pictures in the column layout ([875046f](https://github.com/postalsys/inbox-classic/commit/875046f92180e9dc31881ee9057663300bf36c44))
* **windows:** the column layout, View &gt; Layout and Sort By ([79ccfe5](https://github.com/postalsys/inbox-classic/commit/79ccfe52c5fcdd619a3b98c8a238d1b97e65d630))
* **windows:** View &gt; Folder List, its caption and the folder bar's drop-down ([17354d1](https://github.com/postalsys/inbox-classic/commit/17354d184bdd4b04d9710a9c5d292bd20fc32f85))


### Bug Fixes

* **core:** a contact's picture for a confirmed sender only ([9641726](https://github.com/postalsys/inbox-classic/commit/9641726386fb7370c30c2709d7f8b98727aba5af))
* **core:** a conversation's row keeps its own first words ([7113bab](https://github.com/postalsys/inbox-classic/commit/7113babe14905f8cdda0038b40753c931016b9af))
* **core:** an oversized verdict on top keeps no lower one in its place ([3a62eb6](https://github.com/postalsys/inbox-classic/commit/3a62eb641efd82ca2aef159248d101e0dd081cb8))
* **linux:** room for the folder's name beside the sidebar button ([709c13f](https://github.com/postalsys/inbox-classic/commit/709c13f638e3550b4cece11d18ca2185bad29b72))
* **windows:** no blank band above the column list on a second switch ([4b4f3d3](https://github.com/postalsys/inbox-classic/commit/4b4f3d3c6231d8ecb8c96258aaa2d3a2dc397413))

## [0.15.0](https://github.com/postalsys/inbox-classic/compare/v0.14.2...v0.15.0) (2026-11-13)


### Features

* large messages show their text first ([c2e0ba7](https://github.com/postalsys/inbox-classic/commit/c2e0ba7b25aba3d03f6118bc6db4ecb687e05bca))
* large messages show their text first ([fea650b](https://github.com/postalsys/inbox-classic/commit/fea650b28ff0b5e2ccbaf9ece9a5d99de5c47c14))
* messages downloaded before they are opened ([19b1ab2](https://github.com/postalsys/inbox-classic/commit/19b1ab2aaa797092925ec05d5e3c04913d9b0ff4))
* messages downloaded before they are opened ([9c6d6d9](https://github.com/postalsys/inbox-classic/commit/9c6d6d95426c45733b4c62d323a8880b34c44bee))
* new app icon ([d318fc2](https://github.com/postalsys/inbox-classic/commit/d318fc245267cae5bfb6aa52376143753e3720a0))
* new app icon ([76cf068](https://github.com/postalsys/inbox-classic/commit/76cf068848e05f64937df5951591717bad7e18d6))
* the downloading page says how large the message is ([fa16549](https://github.com/postalsys/inbox-classic/commit/fa165496e7656a1cf3235620adf46d8e98740a20))
* the downloading page says how large the message is ([e4eac5d](https://github.com/postalsys/inbox-classic/commit/e4eac5d88b59484daf76301d70d7d8eda18884e9))


### Bug Fixes

* **core:** hand work to the main worker only when the server refused the connection ([e1e3a69](https://github.com/postalsys/inbox-classic/commit/e1e3a6950796cc259fce49e07c4997f63c0ef4be))
* **core:** room for the workers' deep futures ([4b02391](https://github.com/postalsys/inbox-classic/commit/4b02391a6fa13c9dc160eae1d35212a36d2cb278))
* **core:** the text shown first goes whatever ends the download ([a5f2bf6](https://github.com/postalsys/inbox-classic/commit/a5f2bf662884bda6b447b812b294965b5c6b9208))
* keep the small app icon's corners clear at 16 pixels ([b6317b2](https://github.com/postalsys/inbox-classic/commit/b6317b2d35e5a94d291060d03817a387b14799a7))


### Performance Improvements

* **core:** a reader that is always ready ([6acfeb4](https://github.com/postalsys/inbox-classic/commit/6acfeb462402884df381d53205aa2a0cf822e6d3))
* **core:** a reader that is always ready ([0699cca](https://github.com/postalsys/inbox-classic/commit/0699ccaaa64c0a497d725214d2e43fec7b46b932))
* **core:** background work on a connection of its own ([9df0adc](https://github.com/postalsys/inbox-classic/commit/9df0adc2b7f59c6180d37f5ca4f7fb39139133bb))
* **core:** background work on a connection of its own ([d3cb3fa](https://github.com/postalsys/inbox-classic/commit/d3cb3fadedc6d039d995aaa97d9b20b30b688c31))
* **core:** the user goes first ([ca2386d](https://github.com/postalsys/inbox-classic/commit/ca2386d0dc6e55b2bafaa2282c65700a8bbcac84))
* **core:** the user goes first ([24ea601](https://github.com/postalsys/inbox-classic/commit/24ea60158d998c9ff45df0c1fdff5335daa1142c))
* **core:** time every message open ([62cea77](https://github.com/postalsys/inbox-classic/commit/62cea7701ed4fd088885edea250008f5eefb7b79))
* **core:** time every message open ([a083e98](https://github.com/postalsys/inbox-classic/commit/a083e989bb7201d1ea0c1131e0ef138aadbdc5ca))

## [0.14.2](https://github.com/postalsys/inbox-classic/compare/v0.14.1...v0.14.2) (2026-11-12)


### Bug Fixes

* **linux:** closing the print dialog with its close button no longer crashes ([1144004](https://github.com/postalsys/inbox-classic/commit/114400459436b2b483dfa811f63c28a563f894b4))
* **linux:** closing the print dialog with its close button no longer crashes ([24fdcd3](https://github.com/postalsys/inbox-classic/commit/24fdcd3f36b4288c45873dec84eb317bee55e9a9))

## [0.14.1](https://github.com/postalsys/inbox-classic/compare/v0.14.0...v0.14.1) (2026-11-12)


### Bug Fixes

* **mac, linux:** an unconfirmed sender's note is in the pictures menu, not under the bar ([72d8215](https://github.com/postalsys/inbox-classic/commit/72d82152ea25779e2f6b1be9a58c91142eb60111))
* **mac, linux:** an unconfirmed sender's note is in the pictures menu, not under the bar ([29bf1bf](https://github.com/postalsys/inbox-classic/commit/29bf1bfe548b771828e1a33dc2cb679be4d04cab))

## [0.14.0](https://github.com/postalsys/inbox-classic/compare/v0.13.0...v0.14.0) (2026-11-12)


### Features

* **core:** a message file opened in a window of its own, and answered ([b9be469](https://github.com/postalsys/inbox-classic/commit/b9be4693db87c95da53c9b6ddbc3589a50800a3d))
* **core:** a message file's invitation opened in the calendar ([411e68d](https://github.com/postalsys/inbox-classic/commit/411e68dff3dc8e1adcf2b3ebbdaca92001b28c49))
* **core:** pictures from trusted senders, or in every message ([439b663](https://github.com/postalsys/inbox-classic/commit/439b663c89058a698ae9cec6528b92d9597a55c2))
* **core:** the attachments of a message file ([92eea3a](https://github.com/postalsys/inbox-classic/commit/92eea3ab21b10d5dff6f9a7f3d504091dd36b032))
* **core:** the list's unread messages only, a message read staying listed ([05ee333](https://github.com/postalsys/inbox-classic/commit/05ee333e147f11bdee0bf70023decddbbc0cb6ec))
* **help:** the website's help in the homepage's look ([46e108b](https://github.com/postalsys/inbox-classic/commit/46e108b0a1d8ed29b06bd68cbcf37c1507e29e13))
* **mac, linux:** a message file's attachments saved and its invitation opened ([9e5c80c](https://github.com/postalsys/inbox-classic/commit/9e5c80c7f7381749e73a1f064e55e7cfc31600f5))
* **mac, linux:** pictures from trusted senders, unread only, .eml files ([c244133](https://github.com/postalsys/inbox-classic/commit/c2441337a4845fcb100226475db36f80b896c28c))
* trusted senders' pictures, unread only, .eml files, future dates ([1570819](https://github.com/postalsys/inbox-classic/commit/1570819d99ff5983dbd0b306a4a0526f6b7b2e50))
* **windows:** a message file's attachments saved and its invitation opened ([c9716d5](https://github.com/postalsys/inbox-classic/commit/c9716d58f95a97da1e50fb20f7d757e97151ca48))
* **windows:** pictures from trusted senders, unread only, .eml files, the badge ([d028ed3](https://github.com/postalsys/inbox-classic/commit/d028ed39b0c51364a8b8cd3082e03643fa0765a7))


### Bug Fixes

* **core:** a trusted sender is confirmed only by the provider's topmost verdict, for its own domain ([e8cd3c1](https://github.com/postalsys/inbox-classic/commit/e8cd3c183507f04f4e39afb2ed20d2fee83a0545))
* **core:** unread only allows for SQLite's clock lagging behind on Windows ([be64360](https://github.com/postalsys/inbox-classic/commit/be64360433ae21732afad481ee9b50e944d6849b))
* **store:** a message dated in the future is listed at its arrival ([911e35c](https://github.com/postalsys/inbox-classic/commit/911e35c07bd2bea828c55f85a7e45facd5605109))

## [0.13.0](https://github.com/postalsys/inbox-classic/compare/v0.12.2...v0.13.0) (2026-11-12)


### Features

* a new help, in topics, shown the way each platform shows help ([273e537](https://github.com/postalsys/inbox-classic/commit/273e5376c0113db3cb80b137406bdf333b742a8a))
* **core:** the accounts' order, set by moving an account ([e10a2a2](https://github.com/postalsys/inbox-classic/commit/e10a2a255e41397914f4d7b1ee7c652b685f41b9))
* **help:** the English help as 45 topics ([f59e0b9](https://github.com/postalsys/inbox-classic/commit/f59e0b90e46734234bf1ff0a2d03192b4f48e415))
* **help:** the help in German, Spanish, Estonian and French ([d80f1b5](https://github.com/postalsys/inbox-classic/commit/d80f1b599eabd5fc5f28469ad94fb23915ab75d3))
* **help:** the help on the website ([314e2d2](https://github.com/postalsys/inbox-classic/commit/314e2d2a8b1e9adff7789fef92582734715ee8ad))
* **help:** topics, keys and names from the sources, search and export ([4e7c627](https://github.com/postalsys/inbox-classic/commit/4e7c6275b17a9a6593ec195d9d453121edfd9d5b))
* **linux:** the help in a viewer of its own, or in Yelp ([6d01c6b](https://github.com/postalsys/inbox-classic/commit/6d01c6ba0163168c74c18833356c4f931da75f8f))
* **mac:** the help as an Apple Help Book ([52ec3a2](https://github.com/postalsys/inbox-classic/commit/52ec3a2e8109742348776834dd8f1d862c1df99d))
* reorder accounts by dragging them, or Move Up and Move Down ([c439505](https://github.com/postalsys/inbox-classic/commit/c439505a26f77cd66de22d7e717fce5cdfe28c92))
* reorder accounts by dragging them, or Move Up and Move Down ([553968a](https://github.com/postalsys/inbox-classic/commit/553968a503320871fbf7ac246303dca762fda672))
* **windows:** the help in the classic tri-pane window ([705220b](https://github.com/postalsys/inbox-classic/commit/705220b769b3dfd1a0f90d6e9d14cc98400c1b4f))


### Bug Fixes

* **help:** pictures, the website's sidebar, the Mac's app menu, keys in every language ([fb88e79](https://github.com/postalsys/inbox-classic/commit/fb88e799c62bcbad84697626e8804ccac900e7cb))
* **help:** the English topics reviewed: Mac menu names, steps and sentences ([97309b7](https://github.com/postalsys/inbox-classic/commit/97309b73464cc5492d8a274566e7e8c6d96d8cdb))
* **html:** a message's title is no longer shown as its first line ([9e0655f](https://github.com/postalsys/inbox-classic/commit/9e0655fed5d5ed5659ad49f76363feeac1facbe7))
* **html:** a message's title is no longer shown as its first line ([4509d59](https://github.com/postalsys/inbox-classic/commit/4509d59c1ba3ebecfc456cd158af877e0ddb8617))
* **linux:** no second close button under Omarchy's title bar ([51a03e4](https://github.com/postalsys/inbox-classic/commit/51a03e4884b05c1dd86dcb08819d8b17a3a3be21))
* **linux:** no second close button under Omarchy's title bar ([a98ac8b](https://github.com/postalsys/inbox-classic/commit/a98ac8b76fe71d02d5ea43d3d896c6311f42369e))
* **scripts:** homepage Linux dialog crops for the wider window ([a599504](https://github.com/postalsys/inbox-classic/commit/a599504fb0da57b7dfaec361087851da6739996c))
* **scripts:** the homepage's Linux dialogs cropped where the wider window has them ([9b2dae9](https://github.com/postalsys/inbox-classic/commit/9b2dae99699fefa924d662c82f0a05c204a3d692))
* **scripts:** win-ui-e2e.sh goes on when no app of its directory is running ([d920ebe](https://github.com/postalsys/inbox-classic/commit/d920ebead942bf37b9d5ec20353b3de60bee7e01))

## [0.12.2](https://github.com/postalsys/inbox-classic/compare/v0.12.1...v0.12.2) (2026-11-11)


### Bug Fixes

* a further review of every view, forwarding keeps the attachments ([4af7f91](https://github.com/postalsys/inbox-classic/commit/4af7f9120e5461a2082fa90c4894f74bbed2e08b))
* **linux:** the AI agent's question keeps its last two words together, as the other message boxes ([687ee1c](https://github.com/postalsys/inbox-classic/commit/687ee1ce8dcd39396b12296030c1caf9ca5668cb))
* **mac:** the status bar says Done from the start, as on Windows and Linux ([43fe65d](https://github.com/postalsys/inbox-classic/commit/43fe65d4ac7935c3502f047c7c9dd2a54607af7d))
* review rounds 4 to 6 of every view on all three apps ([c648a14](https://github.com/postalsys/inbox-classic/commit/c648a1477a14cbef4f8a2fe24e9495fda3de8054))
* the verification pass, apostrophes one, issuers and recipients shown whole ([e548e21](https://github.com/postalsys/inbox-classic/commit/e548e21a7a5822a8debe7d5c1afaf1b7fd8ee3e9))
* verification pass 2: the search bar's link beside its words, underline in links ([ff953e4](https://github.com/postalsys/inbox-classic/commit/ff953e4cac640395065b92c4d60a4552cd4168f0))
* verification pass 3: print dates, icons, status text and alignments ([25ec362](https://github.com/postalsys/inbox-classic/commit/25ec36215f2a0f041312943fd52c817174721d6c))
* verification pass 4: delays are not bounces, counts and labels in line ([0dcbb51](https://github.com/postalsys/inbox-classic/commit/0dcbb513fd6e8b1d2115612e9645a745680394a4))
* verification pass 5: the compose title follows the subject, flags on a selection, hyphens kept whole ([6614717](https://github.com/postalsys/inbox-classic/commit/66147170599cd28fa5ddf53272c963224c8958c9))

## [0.12.1](https://github.com/postalsys/inbox-classic/compare/v0.12.0...v0.12.1) (2026-11-11)


### Bug Fixes

* sign-in buttons in each language, the not downloaded message said once ([96f137e](https://github.com/postalsys/inbox-classic/commit/96f137e52eb43a85d8ba8dc12280d916c7e3b64c))
* sign-in buttons in each language, the not downloaded message said once ([64af9b6](https://github.com/postalsys/inbox-classic/commit/64af9b6703ca1a5a65dcbb9f4fbeb1fba4e08291))

## [0.12.0](https://github.com/postalsys/inbox-classic/compare/v0.11.0...v0.12.0) (2026-11-11)


### Features

* Arch Linux package for Omarchy ([82b5a9a](https://github.com/postalsys/inbox-classic/commit/82b5a9afda8dd1f9f68b091ef10c559dad546df6))
* Arch Linux package for Omarchy's package repository ([0965778](https://github.com/postalsys/inbox-classic/commit/0965778c9049e7be8d38990b5ce380392b177449))
* **core:** account names, each account's special folder, an account's Mark All Read ([b84570e](https://github.com/postalsys/inbox-classic/commit/b84570eed8456c7f10131b5ae8b36383eb06c1f0))
* each account's Inbox under All Inboxes, account names, the account's menu ([6307745](https://github.com/postalsys/inbox-classic/commit/63077456ad78de57facfda7e51103c02cdfdd472))
* each account's Inbox under All Inboxes, account names, the account's menu ([2ee3df9](https://github.com/postalsys/inbox-classic/commit/2ee3df93e889c3a2d8de2bad954a56fb7fc4765a))
* **linux:** a window that fits a tiling window manager's narrow tile ([112655f](https://github.com/postalsys/inbox-classic/commit/112655f01f1b6ded444b97ff6e6b4286effda439))
* **release:** Arch packages for x86_64 and aarch64 as release assets ([df98e4c](https://github.com/postalsys/inbox-classic/commit/df98e4c9334797f3f2c2b858dd2669f41702a9ba))


### Bug Fixes

* a review of every view on the three apps, in every language ([051c526](https://github.com/postalsys/inbox-classic/commit/051c526900e6bf7a96da19686aeaca95dd46fcd1))
* **core:** the rows under All Inboxes by the store's Inbox rule, with their titles ([0a170ab](https://github.com/postalsys/inbox-classic/commit/0a170abcfb622afc28d02f75e0ce2dc5fe8f3599))
* **help:** mark the changed Linux removal line for review ([e5d17c3](https://github.com/postalsys/inbox-classic/commit/e5d17c3ea2241591a1a740606bc41cd3bd065f55))
* **linux:** send the tray icon as pixmaps ([6c1e922](https://github.com/postalsys/inbox-classic/commit/6c1e922b63448412ff69a46e19cb81836778190a))
* the Windows app's review, commands on messages off with none selected ([2d7f6c4](https://github.com/postalsys/inbox-classic/commit/2d7f6c4b6edd5b1b0b27421316e3ad0b7d0e567a))

## [0.11.0](https://github.com/postalsys/inbox-classic/compare/v0.10.0...v0.11.0) (2026-11-10)


### Features

* new mail notifications can name a sign-in code ([266d613](https://github.com/postalsys/inbox-classic/commit/266d6134e2941976aec1a4fd081b75343a95f9b2))
* new mail notifications can name a sign-in code ([2a41d28](https://github.com/postalsys/inbox-classic/commit/2a41d283438066bd8d6299084aef48e3e68bbe1e))

## [0.10.0](https://github.com/postalsys/inbox-classic/compare/v0.9.0...v0.10.0) (2026-11-10)


### Features

* a calendar event is a card like the bounce and code cards ([f7b6594](https://github.com/postalsys/inbox-classic/commit/f7b6594c242dc38fa41f6d514a1d5b7031b3ae50))
* a one-time code's card with Copy, from the OTP-Token header or the text ([aa5c6bc](https://github.com/postalsys/inbox-classic/commit/aa5c6bc7743ce0df3006a9b2d2b13612e7c11f84))
* accounts are headings over their folders on the Mac and Linux ([f7105da](https://github.com/postalsys/inbox-classic/commit/f7105daa826903d18cec615287bdfe6c070abc5b))
* accounts are headings over their folders on the Mac and Linux ([619e8e5](https://github.com/postalsys/inbox-classic/commit/619e8e501630d9c128332cc7808fc453e1125c40))
* **core:** one frame for the cards above a message, and a card for calendar events ([f4f162b](https://github.com/postalsys/inbox-classic/commit/f4f162b2dbfb6ce386b6658647c2df560a6945fb))
* one card style for the event, bounce and code cards ([60820d3](https://github.com/postalsys/inbox-classic/commit/60820d31b99d87b70d8503a742ea224b5084e90c))
* one-time codes in a card with Copy (OTP-Token header and pe-otp) ([c71a72c](https://github.com/postalsys/inbox-classic/commit/c71a72ce218a414e08c5b607d3cc9724f71d0a17))
* **pe-mime:** parse the OTP-Token header into Message.otp ([78b779a](https://github.com/postalsys/inbox-classic/commit/78b779a24e40e783d821a7d7820a1cf20155fa9d))
* **pe-otp:** find the one-time code in a message body ([d7098b6](https://github.com/postalsys/inbox-classic/commit/d7098b61b2a78731eb6573243a641a4868b0e2ed))
* Watch and Ignore in the right-click menu, no Watch or Size column ([4082bff](https://github.com/postalsys/inbox-classic/commit/4082bff1d062a81e7ce1e0d8e0c21af3419d2b7f))
* Watch and Ignore in the right-click menu, no Watch or Size column ([d0a9f73](https://github.com/postalsys/inbox-classic/commit/d0a9f7340ec56e1848da822f9d587b01321b236b))


### Bug Fixes

* a code's domain must be its signer's or a host under it ([5276d25](https://github.com/postalsys/inbox-classic/commit/5276d25732316373680a0764d972cb8cd33c4c91))
* centre the "..." of a folded quote and the rows of the Mac's lists ([b3baf4a](https://github.com/postalsys/inbox-classic/commit/b3baf4ab00f49d856a786c1521c2c701ce4db8c6))
* centre the folded quote's dots and the Mac's list rows ([6ecc3d0](https://github.com/postalsys/inbox-classic/commit/6ecc3d0e031ee90b8ef098799c2f866566d3207f))
* port the latest postal-mime and nodemailer security fixes ([290fb15](https://github.com/postalsys/inbox-classic/commit/290fb1537975b4a94acfafe9c100ab90d88bc167))
* port the latest postal-mime and nodemailer security fixes ([30dd7db](https://github.com/postalsys/inbox-classic/commit/30dd7db8206371c3b27ee5a8bc32fb7892538b0f))
* Tab goes from field to field in every form ([c0f176a](https://github.com/postalsys/inbox-classic/commit/c0f176a506ea255b008907099272e79108bf19eb))
* Tab goes from field to field in every form ([43a63d9](https://github.com/postalsys/inbox-classic/commit/43a63d96ba792b1e8e55543a82e215dff2e2718b))
* Tab reaches the message, its links and the lists' neighbours ([14d9e41](https://github.com/postalsys/inbox-classic/commit/14d9e419788b9f046aeeafdd45407846057a429d))

## [0.9.0](https://github.com/postalsys/inbox-classic/compare/v0.8.0...v0.9.0) (2026-11-10)


### Features

* a message in a window of its own ([5f6dba2](https://github.com/postalsys/inbox-classic/commit/5f6dba2168e279a702cdc785dae293749faba94b))
* Archive ([95e8441](https://github.com/postalsys/inbox-classic/commit/95e8441d9f9805378248570c75ada5fea735a99d))
* bounces explained in the reading pane ([f46d86b](https://github.com/postalsys/inbox-classic/commit/f46d86b312d9e34211ebd339f0ec9ea325c1010e))
* conversations in the message list ([fc9469e](https://github.com/postalsys/inbox-classic/commit/fc9469e36ed39fc093bd19ed4cd43d2fe4e0cde2))
* **core:** a ListView keeps what a message list shows ([cc40bf9](https://github.com/postalsys/inbox-classic/commit/cc40bf9fc05d3dda8d818357cf1fbf0d6c965bde))
* **core:** Archive, into the Archive folder or off every Gmail label ([eacaa60](https://github.com/postalsys/inbox-classic/commit/eacaa60a01aef3d3be164259f3489e19cf42bab4))
* **core:** bounces explained in the reading pane ([ce7d98c](https://github.com/postalsys/inbox-classic/commit/ce7d98cffb00d5f3383e8d89f16469434548c0f5))
* **core:** conversations in the store ([3207811](https://github.com/postalsys/inbox-classic/commit/320781105ebdb3f0dabbf88ce2c75df545578388))
* **core:** conversations in the store ([389fad1](https://github.com/postalsys/inbox-classic/commit/389fad1d084d48cdbdfecb1f97886cfeb6c62374))
* **core:** Empty Folder for Deleted Items and Junk E-mail ([326d468](https://github.com/postalsys/inbox-classic/commit/326d468ffeafa5057bf540806ebb31708bec7460))
* **core:** Next Unread as one step, the commands of keyboard reading ([dce0dbb](https://github.com/postalsys/inbox-classic/commit/dce0dbb250f985c837c0d518689d2daec8b5e3ce))
* **core:** Next Unread in a list grouped by conversation ([14cc6a0](https://github.com/postalsys/inbox-classic/commit/14cc6a0e832fe67fdbffd5c4851965a0f8b92d96))
* **core:** pe_address_is_mailbox for the address the user types ([a789d3a](https://github.com/postalsys/inbox-classic/commit/a789d3abea994f2e5a426c418bc4c57bd44f0af8))
* **core:** pe-bounce, bounces found and explained ([8a63298](https://github.com/postalsys/inbox-classic/commit/8a632982a423ddd06b37d34859fa4100b714d1a1))
* **core:** pe-bounce, bounces found and explained ([a1ab805](https://github.com/postalsys/inbox-classic/commit/a1ab805069e7251593235c809763f6976d98023f))
* **core:** Sent Items and Drafts list whom a message went to ([bca9b06](https://github.com/postalsys/inbox-classic/commit/bca9b06d0cdf62653b061f7ad6e33fbcd8992057))
* **core:** the address book ([d493074](https://github.com/postalsys/inbox-classic/commit/d49307424a1f6fa99daad4659d6977772cd00fd7))
* **core:** the Address Book through the C API ([b8d9443](https://github.com/postalsys/inbox-classic/commit/b8d9443fe8ff889049f25e87f891164a09affa11))
* **core:** the address book, vCard and CSV ([521f5bf](https://github.com/postalsys/inbox-classic/commit/521f5bf0c1b8209a46abeebf63fe9c7af778b9f8))
* **core:** the message list grouped by conversation through the C API ([6d98fc1](https://github.com/postalsys/inbox-classic/commit/6d98fc1804a2474222049a09916796e8dd496e3c))
* **core:** the messages before and after one in a list, in one pass ([0857d3d](https://github.com/postalsys/inbox-classic/commit/0857d3d5ead0b778667f40ac0d167116a94f597d))
* **core:** Watch and Ignore Conversation ([e3e610a](https://github.com/postalsys/inbox-classic/commit/e3e610ae540b199ee039a94131386b0739d5b38f))
* Empty Deleted Items and Junk E-mail ([fc6c39c](https://github.com/postalsys/inbox-classic/commit/fc6c39cb32610d5b2aeaa35db0508c5c88f8f5aa))
* **ffi:** PeListView, the message list's view through C ([8b3f50b](https://github.com/postalsys/inbox-classic/commit/8b3f50bd3ff97ac1b03738a6add75f3a75f0d593))
* **i18n:** German, Estonian, Spanish and French reviewed ([851cef4](https://github.com/postalsys/inbox-classic/commit/851cef4718467ea3c1b9cd09296dd04b9b80b8f9))
* **i18n:** Previous and Next ([9bed18c](https://github.com/postalsys/inbox-classic/commit/9bed18ce0f4b13468a376d2a314bf73768ea0a5d))
* **i18n:** the Address Book in German, Estonian, Spanish and French ([1d80e16](https://github.com/postalsys/inbox-classic/commit/1d80e1671426ed88036d265d650670b15e29c81c))
* **i18n:** the bounce card in German, Estonian, Spanish and French ([0c518e1](https://github.com/postalsys/inbox-classic/commit/0c518e1ea076407c65c523491233bfbb651d58c2))
* **i18n:** the new features' translations reviewed ([30bb0f4](https://github.com/postalsys/inbox-classic/commit/30bb0f40eaae18fb43bb155aa757b9441e0a05e3))
* **i18n:** the words of Archive ([a6379b5](https://github.com/postalsys/inbox-classic/commit/a6379b55c7a660d6535110aaf84645bf1bbf0fab))
* **i18n:** the words of Empty Folder; the review list keeps paragraphs ([8e29ce6](https://github.com/postalsys/inbox-classic/commit/8e29ce6d683c8df812ebac2415138a42d8ed19f1))
* **i18n:** the words of keyboard reading; markup lines need no review ([9af72c7](https://github.com/postalsys/inbox-classic/commit/9af72c70f0eea6ed4b2b4066229205f8d1486b46))
* **i18n:** To and Sent column titles shared by every app ([a35aba0](https://github.com/postalsys/inbox-classic/commit/a35aba0cd95fdac085272fc9ad71718d3c8ab50d))
* **i18n:** Watch and Ignore in German, Estonian, Spanish and French ([ffb445c](https://github.com/postalsys/inbox-classic/commit/ffb445c5c1fd199be8571b7b50ab5c523fcc90de))
* **imap:** Gmail labels and conversations in FETCH, labels in STORE, CREATE for a special use ([6fdde92](https://github.com/postalsys/inbox-classic/commit/6fdde92acf63584fa2f2f43c9aae0ba65712cb62))
* **linux:** a message in a window of its own ([e2095ab](https://github.com/postalsys/inbox-classic/commit/e2095ab25cf0541911dfb498292d170e65e70634))
* **linux:** Archive on the header bar, in the menus and on the A key ([bfdd1ee](https://github.com/postalsys/inbox-classic/commit/bfdd1ee286127514988c45d538cadacd0630a986))
* **linux:** bounces explained ([3a20311](https://github.com/postalsys/inbox-classic/commit/3a20311c597f880536bfcee53e05fb9e85f11a13))
* **linux:** conversations in the message list ([4939eb3](https://github.com/postalsys/inbox-classic/commit/4939eb3cbdc017772d02dd3705ce123f28d19d61))
* **linux:** Empty Folder in the menu and on the folder's menu ([ea795c2](https://github.com/postalsys/inbox-classic/commit/ea795c22f6949e8c35f3e8aab9965c642290ab66))
* **linux:** keyboard reading, Go to Folder, a find bar over the message ([d9fdae0](https://github.com/postalsys/inbox-classic/commit/d9fdae0aee74a29b769467290b427e186df8c448))
* **linux:** the Address Book ([14260a9](https://github.com/postalsys/inbox-classic/commit/14260a9abe37678b2407f32df952cf067f261ff5))
* **linux:** To and Sent columns in Sent Items and Drafts ([bba481e](https://github.com/postalsys/inbox-classic/commit/bba481e72328380a3a5401c7557a58b6fa0085e3))
* **linux:** Watch and Ignore Conversation ([a38dc8c](https://github.com/postalsys/inbox-classic/commit/a38dc8cd05b8676e7375e067e175af1c939a83cb))
* **mac:** a message in a window of its own ([0a23292](https://github.com/postalsys/inbox-classic/commit/0a232926cab7eecd14d267b6856c89b04385b993))
* **mac:** Archive on the toolbar, in the menus and on the A key ([4fb7b11](https://github.com/postalsys/inbox-classic/commit/4fb7b110a4e02496f2f42e471137c0a2abe3ba44))
* **mac:** bounces explained ([021f407](https://github.com/postalsys/inbox-classic/commit/021f4072076991899396e5fe4060a04421090169))
* **mac:** conversations in the message list ([4a133ef](https://github.com/postalsys/inbox-classic/commit/4a133ef5556ce1aaf22a0f151762b468a2a884ce))
* **mac:** Empty Folder in the File menu and on the folder's menu ([0d0096c](https://github.com/postalsys/inbox-classic/commit/0d0096c94aa3b0266dc4bea70de6204e5531770a))
* **mac:** keyboard reading, Go to Folder, a find bar over the message ([8f7a2ef](https://github.com/postalsys/inbox-classic/commit/8f7a2ef8bc70d70dece7a1d840f21a8274c42681))
* **mac:** the Address Book ([600b02b](https://github.com/postalsys/inbox-classic/commit/600b02ba90c900fbe56a8f6497a8ecb81e19dbec))
* **mac:** To and Sent columns in Sent Items and Drafts ([7485019](https://github.com/postalsys/inbox-classic/commit/7485019bf49c9f8efb957d64b8033cdec2323adf))
* **mac:** Watch and Ignore Conversation ([aee0582](https://github.com/postalsys/inbox-classic/commit/aee058221d13bb14912d207df823af2e093dc54c))
* reading with the keyboard ([93bbd11](https://github.com/postalsys/inbox-classic/commit/93bbd115b4e97c8e310d73954e7338eb189c1558))
* the Address Book ([cf0d79f](https://github.com/postalsys/inbox-classic/commit/cf0d79f92be1c2e102d8a19d609c1ece8c18ddf1))
* the recipients column in Sent Items and Drafts ([a1a010b](https://github.com/postalsys/inbox-classic/commit/a1a010b56a5c6a5bb9ffec39137213277f231852))
* Watch and Ignore Conversation ([6f10659](https://github.com/postalsys/inbox-classic/commit/6f10659dbd21a1b0ba376b2bc7dd9cf7998a57b6))
* **windows:** a message in a window of its own, the reading pane as a Reader ([c0af489](https://github.com/postalsys/inbox-classic/commit/c0af48935c3f1e85886db7ec31ee4e7f3862e04d))
* **windows:** Archive on the toolbar, in the menus and on the A key ([bfce46e](https://github.com/postalsys/inbox-classic/commit/bfce46e176e50e03b1acb97617c2f00bb3c5e098))
* **windows:** bounces explained ([3afffa2](https://github.com/postalsys/inbox-classic/commit/3afffa251502b0fe15659ca9da6c1311d477d81e))
* **windows:** conversations in the message list ([cb79949](https://github.com/postalsys/inbox-classic/commit/cb79949dbefd8661b4386a53e22951c88c9a3a11))
* **windows:** Empty Folder in File &gt; Folder and on the folder's menu ([47270e6](https://github.com/postalsys/inbox-classic/commit/47270e67dc9b65c8a07f8d5712a6849e599e64f2))
* **windows:** keyboard reading, Go to Folder, Find in This Message ([7f4c033](https://github.com/postalsys/inbox-classic/commit/7f4c03302702ba4c851126b494dc9f1cdefdf811))
* **windows:** the Address Book ([74a13cb](https://github.com/postalsys/inbox-classic/commit/74a13cbaf78e54a2ae1a48accf5355216415fc78))
* **windows:** To and Sent columns in Sent Items and Drafts ([ce52d54](https://github.com/postalsys/inbox-classic/commit/ce52d547ac4dcb596c5c1b99f37eaa3f8e298bd8))
* **windows:** Watch and Ignore Conversation ([44dc1df](https://github.com/postalsys/inbox-classic/commit/44dc1df46b0235bdcd0999d3de3c90fb1689b437))


### Bug Fixes

* **ci:** run again when a label is added or removed ([95a4cf1](https://github.com/postalsys/inbox-classic/commit/95a4cf1a51df1071fa5a780011e43729d808fe4e))
* **core:** a collapsed conversation shows its newest message's date ([4b49177](https://github.com/postalsys/inbox-classic/commit/4b49177dfdda9392b55155ca9616bd16b9cb7fd2))
* **core:** a conversation's first message is the first to arrive ([466a57b](https://github.com/postalsys/inbox-classic/commit/466a57b9a5a295f7ac79a11226a1f37fbf886140))
* **core:** a delivery report's parts for servers are not listed as files ([d5bd2f2](https://github.com/postalsys/inbox-classic/commit/d5bd2f2443f377d44692c92bbd95e02f1d246767))
* **core:** a grouped selection keeps the list's order ([a484ce2](https://github.com/postalsys/inbox-classic/commit/a484ce2f027f66551c309a93c99175a33bf0e7da))
* **core:** Expand All on a huge folder no longer exceeds SQLite's bound values ([d7c7bbf](https://github.com/postalsys/inbox-classic/commit/d7c7bbf5a916ed5735ce422aa91aeb39cbe6b2a8))
* **core:** the three issues left open in the log ([16a3ce9](https://github.com/postalsys/inbox-classic/commit/16a3ce930a05bfbd1ba1ab38c8209ea46b328696))
* **e2e:** Linux adds an account only once the last server form is closed ([41d416c](https://github.com/postalsys/inbox-classic/commit/41d416c75f9c3707ef6621e9de61048c670ccf5f))
* **e2e:** Linux waits for the Junk and Archive moves to leave the Inbox ([f129cfa](https://github.com/postalsys/inbox-classic/commit/f129cfa76d8ae01f845a7ad479a39db6e73f8e02))
* **e2e:** the Windows bounce step finds the card's words once it can ([526aafd](https://github.com/postalsys/inbox-classic/commit/526aafde2199a0a5ccf6c540140b5c3fccc413cf))
* **e2e:** the Windows test counts the Watch column ([2651a74](https://github.com/postalsys/inbox-classic/commit/2651a74f5ad913a90b1ae19c1b99a28bf221383a))
* **e2e:** Windows adds a contact's addresses one at a time ([e04e8f6](https://github.com/postalsys/inbox-classic/commit/e04e8f6e8e5b6bbe6d0e776e3898529e2acd5756))
* **e2e:** Windows adds a contact's addresses one at a time ([de8a5d5](https://github.com/postalsys/inbox-classic/commit/de8a5d53b712c72ca1a1fc2c1387b9b54522529f))
* **e2e:** Windows selects the logo's message until it shows, and right-clicks topmost ([2d06ae3](https://github.com/postalsys/inbox-classic/commit/2d06ae36ffd5b2c91ce5eecdb07751d0554ad6a4))
* **i18n:** a help line that changed only by a search keyword needs no review ([581c9ce](https://github.com/postalsys/inbox-classic/commit/581c9ce8de159cab8c6fe85d4e2689b70a7c0aed))
* **i18n:** Expand All Conversations is marked for review ([48afe4c](https://github.com/postalsys/inbox-classic/commit/48afe4c4034efa587f35bed43891593a542d8a89))
* **i18n:** the arrows of Select Recipients' buttons are arrows ([13d5c2d](https://github.com/postalsys/inbox-classic/commit/13d5c2d52728dd401440378731b226dad234740c))
* **i18n:** Thunderbird's wording where it reads better ([097322f](https://github.com/postalsys/inbox-classic/commit/097322f44f30f9c90d02eb7139eb4fb0ee884cc4))
* **linux:** clippy's then_some in Previous and Next ([4d7a102](https://github.com/postalsys/inbox-classic/commit/4d7a10275fe6b823b1d71c24ac90941671ad634f))
* **mac:** the Folder column of a search leaves Size whole ([c2d5edc](https://github.com/postalsys/inbox-classic/commit/c2d5edca045baeb17ebc3c03147aa660adafd4aa))
* **mac:** the Folder column of a search leaves Size whole ([617aa9b](https://github.com/postalsys/inbox-classic/commit/617aa9b8a736156d2e99dac56c230d1d49ed9630))
* **scripts:** a copy from another checkout clears the old sources first ([feb6b2c](https://github.com/postalsys/inbox-classic/commit/feb6b2c0d31f9db6f54cf0b053e81f348a04037e))
* **scripts:** the Windows build rebuilds what another checkout changed ([d60cff6](https://github.com/postalsys/inbox-classic/commit/d60cff6f46bb45f06367c6e1103095c7f4ad2fee))
* **scripts:** the Windows build rebuilds what another checkout changed ([691b55d](https://github.com/postalsys/inbox-classic/commit/691b55d274e418b5909140f830a2c483ff6f49a6))
* **scripts:** the Windows build rebuilds what another checkout changed ([8bd9a65](https://github.com/postalsys/inbox-classic/commit/8bd9a652ef442853cb53960c11ea2e25f2c57a94))
* the MCP test waits for the store, cargo fmt of the Linux app ([a40ef77](https://github.com/postalsys/inbox-classic/commit/a40ef773632df95aafd7e6ea2e421c9313af9e68))
* **windows:** the toolbar keeps its labels after the window is minimized ([bec19ab](https://github.com/postalsys/inbox-classic/commit/bec19abdb99a4b789a158a01c5ffb5fbc29ea26a))
* **windows:** the toolbar keeps its labels after the window is minimized ([8c56cb2](https://github.com/postalsys/inbox-classic/commit/8c56cb2cb4705f06a500bf55f8aaf47a1a9f87c8))

## [0.8.0](https://github.com/postalsys/inbox-classic/compare/v0.7.0...v0.8.0) (2026-11-06)


### Features

* All Inboxes, and opening on the newest message ([4607c7f](https://github.com/postalsys/inbox-classic/commit/4607c7f7537948ace9f3d9e662de662d0eaa28dc))
* All Inboxes, the mail of every account's Inbox in one list ([0c88472](https://github.com/postalsys/inbox-classic/commit/0c88472d391f6021d455925ab6a740e1f9acadc7))
* **core:** files put in a folder say so in the status bar ([88ffc8f](https://github.com/postalsys/inbox-classic/commit/88ffc8fc1a72355d5c254d077d6fe716d2aad300))
* **core:** flag colours as Apple Mail keeps them ([6f6073a](https://github.com/postalsys/inbox-classic/commit/6f6073a2ae2d62d6236e92568787e9f84ceec788))
* **core:** Forward and Save As for several messages, their status texts ([8d945a2](https://github.com/postalsys/inbox-classic/commit/8d945a296257c5e26c58efa7f9390944beb2294f))
* **core:** German, Estonian, French and Spanish catalogs (drafts) ([513da8d](https://github.com/postalsys/inbox-classic/commit/513da8dd34fec93f79add61bfad3a936ea866f3f))
* **core:** messages as .eml files, several saved or forwarded at once ([ae7fb42](https://github.com/postalsys/inbox-classic/commit/ae7fb424410c5ea8a815b7836caa0ea560f156bc))
* **core:** move and copy messages between accounts ([ccb9e00](https://github.com/postalsys/inbox-classic/commit/ccb9e00c350a754e69b79dbd71d078ef0350af46))
* **core:** selections of messages, batch actions and undo ([75c602d](https://github.com/postalsys/inbox-classic/commit/75c602db583533dc2bbf8edb8769e084025f2c5c))
* **core:** the help in German, Estonian, French and Spanish (drafts) ([739e4d3](https://github.com/postalsys/inbox-classic/commit/739e4d349717aced89bfc7502f7b3210acd8c48b))
* **core:** the Move and Copy window's words ([40b9a9c](https://github.com/postalsys/inbox-classic/commit/40b9a9cd56d9ddc8ece3333ab1c0c6b4bbf8f770))
* **core:** the Options command, its help, scenario and feature map ([bf76ec7](https://github.com/postalsys/inbox-classic/commit/bf76ec7d3f71927ca00130f24e63af61fd922e72))
* **core:** the words of the windows in Fluent catalogs, the language API ([1352e13](https://github.com/postalsys/inbox-classic/commit/1352e1345d9e7ee27eecc511ec2aa28d421ba953))
* flag colours as Apple Mail keeps them ([fdade16](https://github.com/postalsys/inbox-classic/commit/fdade1685857d065cf94e5dee046bc4e8634caa7))
* flag colours on the Mac and Linux ([de3a22f](https://github.com/postalsys/inbox-classic/commit/de3a22f12548383dbcf19398f63eae6661524046))
* flag colours on Windows; the message menu with the Flag submenu alone ([5b36af3](https://github.com/postalsys/inbox-classic/commit/5b36af35396c33e1c3735d74cd0ae0ec9a3136fe))
* **i18n:** the reviewed German, Estonian, French and Spanish translations ([5b2155a](https://github.com/postalsys/inbox-classic/commit/5b2155ab7763fc4a66d01afaf10d30e4b5037f3c))
* **linux:** files put in a folder say so in the status bar ([5b1e988](https://github.com/postalsys/inbox-classic/commit/5b1e98829f91f0951227f4623f763bf12b2221ae))
* **linux:** the windows in five languages, Preferences with the language; Archive named in the language ([2c9b953](https://github.com/postalsys/inbox-classic/commit/2c9b953f96f82178707aa0e024e6b6e2d52d6d1e))
* **mac:** files put in a folder say so in the status bar ([1bba909](https://github.com/postalsys/inbox-classic/commit/1bba9095c9a6d31d0a1e90f562d1a5d7b42dca12))
* **mac:** the windows in five languages, Settings with the language, the app's own language in macOS ([d0d2dd2](https://github.com/postalsys/inbox-classic/commit/d0d2dd22684e7a132efd1a1c934a87118cc2b97c))
* messages as files on the Mac and Linux, the list without the envelope column ([1178459](https://github.com/postalsys/inbox-classic/commit/1178459b29a99f00d8ce9971dd38b23c94a121a9))
* messages as files: drag out, drop in, Save As and Forward several ([177a837](https://github.com/postalsys/inbox-classic/commit/177a837d91fff24faa50826fdbb02072df557d05))
* move and copy messages between accounts ([34ce542](https://github.com/postalsys/inbox-classic/commit/34ce54208ca977020a91c7be0ef9c6eebea0aa1d))
* move and copy messages between accounts on the Mac and Linux, the Move and Copy window ([3f7f447](https://github.com/postalsys/inbox-classic/commit/3f7f447b176f96e8cc5fffeeb7943bf981c6e824))
* move and copy messages between accounts on Windows, the Move and Copy window ([57aeb87](https://github.com/postalsys/inbox-classic/commit/57aeb871c5a592ab31a8f9accabe68df634a048e))
* open on the newest message of the first Inbox, Save As in View Source ([a1cf5ec](https://github.com/postalsys/inbox-classic/commit/a1cf5ec12bb449666178a7b774ead328d9358e63))
* select several messages, act on all of them, and undo ([03b6d72](https://github.com/postalsys/inbox-classic/commit/03b6d7201f983d38eae30311ed1fd4b44d39326a))
* select several messages, act on all of them, and undo ([61e4c72](https://github.com/postalsys/inbox-classic/commit/61e4c725465649131d197470e32012ddedb4b4c9))
* the windows in five languages (draft translations) ([222d8d6](https://github.com/postalsys/inbox-classic/commit/222d8d6ceb6b83ef4b33fcf7b24f742ab71fe22e))
* **windows:** every word from the catalogs, Tools &gt; Options with the language, the installer in five languages ([d189bea](https://github.com/postalsys/inbox-classic/commit/d189bea79e33e4ab9dc688b3d2215e8dea263ecc))
* **windows:** messages as files, OLE drag and drop, the list without the envelope column ([41b9f73](https://github.com/postalsys/inbox-classic/commit/41b9f73bcc4f9fd356ff697b630f635ef5bac719))


### Bug Fixes

* All Inboxes' right-click menu has Mark All Read alone ([44478c4](https://github.com/postalsys/inbox-classic/commit/44478c421903257cbe21f46542130f5b49f4f2eb))
* All Inboxes' right-click menu has Mark All Read alone ([6e09f20](https://github.com/postalsys/inbox-classic/commit/6e09f2052329cc588e57213eaa97658080a31b85))
* **core:** attachments of drafts and forwards written to a folder of the user's own ([f50547d](https://github.com/postalsys/inbox-classic/commit/f50547d826c63b5da5727cb92bc5f0e14d18fa8b))
* **core:** file names that fit every file system, the downloading text for what is missing, commands for several messages ([724d27f](https://github.com/postalsys/inbox-classic/commit/724d27fb01d687e4b9c19dc405d86a3e447ed3e6))
* **core:** flag changes stored silently, so an older reply never shows over a newer change ([f0981b2](https://github.com/postalsys/inbox-classic/commit/f0981b29b9da9f142d3a842fcd36f44039a42f77))
* **core:** only leftovers a day old are cleared, not another running core's files ([37a309d](https://github.com/postalsys/inbox-classic/commit/37a309d6dcff894174d85e128ed10aef73739cac))
* **core:** status texts agree with the number of messages in every language ([e1d2cb4](https://github.com/postalsys/inbox-classic/commit/e1d2cb405153831f141ce36307dcee69ea5fa27f))
* folder names from the core on every platform, the Archive folder in the language on the Mac ([c6031cb](https://github.com/postalsys/inbox-classic/commit/c6031cb09f7d67e0be0fcf50a351304ea2054769))
* folder names from the core, Archive translated on the Mac ([cc3d517](https://github.com/postalsys/inbox-classic/commit/cc3d517344ecebe526531fcbf93837ebe25a4da2))
* **mac:** restart only when the app really quits, the language actually used for dates, a restart asked only when the language changes ([e4908d0](https://github.com/postalsys/inbox-classic/commit/e4908d0fe468b04d593e49b6a8e6bd4f41a7be94))
* registration hint translated, toolbar buttons never under the Find box ([3038164](https://github.com/postalsys/inbox-classic/commit/3038164ad316ee76031d8c92d3a4cfa1ab9d047f))
* texts with values keep their ampersands and leading zeros, English leftovers gone, plurals for repeats ([25fb498](https://github.com/postalsys/inbox-classic/commit/25fb4981b5dfb4a6bf4d88dea82fdd700761d3db))
* the sign-in app's registration hint in the language, toolbar buttons never under the Find box ([082a568](https://github.com/postalsys/inbox-classic/commit/082a568154a4ac0d7451a99356b4279340acfb8b))
* **windows:** an Archive folder named in the language, as on the Mac and Linux ([81d6eb9](https://github.com/postalsys/inbox-classic/commit/81d6eb9119fcc512eef5422e06276e681a267b81))
* **windows:** flags white on selected rows, one-message items greyed in the message menu again ([59337c5](https://github.com/postalsys/inbox-classic/commit/59337c538ec2dee2fabf6a4fa0a1a3df2ffdd89f))
* **windows:** the Find box gives way to longer toolbar words, Options without group boxes ([37f7316](https://github.com/postalsys/inbox-classic/commit/37f731635fac71cc762c75d20c7e77fbcb081a6d))
* **windows:** window titles without the menu's "...", and the UI test's language steps ([4bab623](https://github.com/postalsys/inbox-classic/commit/4bab623ffe3ab9b12e2a0ce31845647669a8895b))

## [0.7.0](https://github.com/postalsys/inbox-classic/compare/v0.6.0...v0.7.0) (2026-11-05)


### Features

* AI agents (MCP), message menu and source, unread in collapsed folders ([#9](https://github.com/postalsys/inbox-classic/issues/9)) ([16abc1f](https://github.com/postalsys/inbox-classic/commit/16abc1f3318eb9e2ee06da5288c8162d9e193db7))

## [0.6.0](https://github.com/postalsys/inbox-classic/compare/v0.5.1...v0.6.0) (2026-11-04)


### Features

* say when a message is being downloaded, and why it could not be ([913f863](https://github.com/postalsys/inbox-classic/commit/913f86342ecfdefecbd4c9b27ca68e057169e305))

## [0.5.1](https://github.com/postalsys/inbox-classic/compare/v0.5.0...v0.5.1) (2026-11-04)


### Bug Fixes

* **mac:** the message list no longer starts squeezed to its smallest ([4483dc2](https://github.com/postalsys/inbox-classic/commit/4483dc2bf16c0db11a678e31346871fb5725da87))

## [0.5.0](https://github.com/postalsys/inbox-classic/compare/v0.4.1...v0.5.0) (2026-11-04)


### Features

* **core:** account labels, folder names and the version for every shell ([193d715](https://github.com/postalsys/inbox-classic/commit/193d715f296468c59857b06bb54772af36c54f32))
* **linux:** packaging, CI, the VM and the rest of the UI test ([e7886ed](https://github.com/postalsys/inbox-classic/commit/e7886ed0f0203eed744d6c6cda4eb723b2df25a5))
* **linux:** the Flatpak, on the GNOME runtime ([0df877b](https://github.com/postalsys/inbox-classic/commit/0df877bc4e818ff2d94b1e5cee9ed74f78f42e58))
* **linux:** the GTK 4 app with its in-process UI test ([5c2913d](https://github.com/postalsys/inbox-classic/commit/5c2913d68aedd44a4714866c59bfc1ae66c321a1))
* Mac updates, packaging and the full UI test; the release for every platform ([08f9296](https://github.com/postalsys/inbox-classic/commit/08f9296af5f6d738c9448d2a05be23ee330a28be))
* **mac:** the Mac app, native AppKit on the Rust core ([ffa857a](https://github.com/postalsys/inbox-classic/commit/ffa857a1fd9e75e390b668a5cf6632dc8179cfc2))
* the shared pieces for the Mac and Linux versions ([fd61c1a](https://github.com/postalsys/inbox-classic/commit/fd61c1aa25f02b2fdd56c047cb2ea2e802cfc450))


### Bug Fixes

* an unsigned Mac package for a look, without the hardened runtime ([a95ec33](https://github.com/postalsys/inbox-classic/commit/a95ec33025a7b569ec9e2f71463fceab3c3be6eb))
* **linux:** build the amd64 image under Rosetta, lint without the e2e feature ([590e7d3](https://github.com/postalsys/inbox-classic/commit/590e7d3c25fcf20019690e0773dcaa806c99a336))
* **mac:** room for the size beside the Folder column of a search ([0df0dea](https://github.com/postalsys/inbox-classic/commit/0df0dea63f5a06d462268968e3fc0cd82a51c2b4))

## [0.4.1](https://github.com/postalsys/inbox-classic/compare/v0.4.0...v0.4.1) (2026-11-04)


### Bug Fixes

* keep the toolbar from painting over the search field ([404d1ff](https://github.com/postalsys/inbox-classic/commit/404d1fff5ad84776b0bcb90660deeef5fa5779a9))

## [0.4.0](https://github.com/postalsys/inbox-classic/compare/v0.3.0...v0.4.0) (2026-11-04)


### Features

* a signature for each account ([b61db76](https://github.com/postalsys/inbox-classic/commit/b61db761850c6e59b9891487f049d6d10842c826))
* a slim search bar over the list ([c1d1f75](https://github.com/postalsys/inbox-classic/commit/c1d1f755447c0dedf52510b947aa1cc96c06f8f9))
* brand logos (BIMI) beside the header ([cc31b74](https://github.com/postalsys/inbox-classic/commit/cc31b740a78eaecc47fc2e4241a2caa7aa569dc5))
* calendar invitations shown readably ([120b921](https://github.com/postalsys/inbox-classic/commit/120b921f3de845e40269383604dfe8bf1fa69d37))
* complete addresses from the people written to and heard from ([abe5a88](https://github.com/postalsys/inbox-classic/commit/abe5a88777cc215077ab9f422c57bdc7936c143f))
* local full-text search with Gmail query syntax ([87cd7cc](https://github.com/postalsys/inbox-classic/commit/87cd7cc97fa771746d77a25142c2634f4a35af04))
* Mark All Read, dragging messages onto folders, Junk and Not Junk ([4a53a4d](https://github.com/postalsys/inbox-classic/commit/4a53a4d91bb5efb1f58fec77157fd42b7dee938f))
* new mail as it arrives, in the tray and as a notification ([a9176bc](https://github.com/postalsys/inbox-classic/commit/a9176bcba4a2c75817dcd553708ff9a212fea5f4))
* search every folder from one search field ([836b575](https://github.com/postalsys/inbox-classic/commit/836b5758400cfc409c2b34656a726f34d41c1eaa))
* the default mail app for mailto: links ([9742fb5](https://github.com/postalsys/inbox-classic/commit/9742fb545db7e29c01b6fb207578b16111bcb809))
* Unsubscribe from mailing lists ([86d5e98](https://github.com/postalsys/inbox-classic/commit/86d5e98be54ee842b920c193c3c5413d2c28835c))

## [0.3.0](https://github.com/postalsys/inbox-classic/compare/v0.2.0...v0.3.0) (2026-11-03)


### Features

* links in a message being written can be seen, opened, changed and removed ([6b2bc15](https://github.com/postalsys/inbox-classic/commit/6b2bc15dad953234387fd728cf275f5983ef5dba))
* pictures dragged onto the text go in as Insert Picture puts them ([ed7a8f6](https://github.com/postalsys/inbox-classic/commit/ed7a8f636b0752783914e938ab80b0a1538d3cd2))

## [0.2.0](https://github.com/postalsys/inbox-classic/compare/v0.1.0...v0.2.0) (2026-11-03)


### Features

* sign-in apps, OAuth clients of your own at any OpenID Connect provider ([f1a28c8](https://github.com/postalsys/inbox-classic/commit/f1a28c8202ada9077d1469140ea6ff8f654ac7ff))

## 0.1.0 (2026-11-03)


### ⚠ BREAKING CHANGES

* **compose:** remove Send Later

### Features

* **accounts:** Sign in with Google and Microsoft buttons, no password up front ([4e8dfeb](https://github.com/postalsys/inbox-classic/commit/4e8dfeb9bda756f9a5d5cbb68eff48d9362e09fb))
* **app:** Outlook Express style mail window on the core ([efb1b0c](https://github.com/postalsys/inbox-classic/commit/efb1b0cf75dccbfe87ef6d77061503224afd1fb9))
* **compose:** a From row that shows and chooses the sending account ([f4fb19e](https://github.com/postalsys/inbox-classic/commit/f4fb19e7aa13df37e22207de2872a2ec79afbae8))
* **compose:** message windows of their own, and saying what Save and Send did ([f269b1b](https://github.com/postalsys/inbox-classic/commit/f269b1bf4ae4c60a77bbcd3d9d1b0adecf2de955))
* **compose:** plain text when nothing is formatted; Cc and Bcc on demand ([cf865eb](https://github.com/postalsys/inbox-classic/commit/cf865ebd80764de5665499f17fbeed93b5b9fe4b))
* **compose:** remove Send Later ([091d1d1](https://github.com/postalsys/inbox-classic/commit/091d1d1120bc281308c8c99fb78d6e75b556bc87))
* **compose:** WYSIWYG HTML editor, the quote folded behind "..." ([2d0defd](https://github.com/postalsys/inbox-classic/commit/2d0defd527b0ad4ff65b00ef4daafee094a97273))
* **core,autoconfig:** saved passwords and server lookup for new accounts ([3f852f5](https://github.com/postalsys/inbox-classic/commit/3f852f5fd887c3e3bb08f1f020a93fdfbbb1843d))
* **core,ffi:** mail engine and C API v1 ([cfffe46](https://github.com/postalsys/inbox-classic/commit/cfffe466739a42394dd98a00710f38cbbe859ca0))
* delete, move and flag messages ([76f4c27](https://github.com/postalsys/inbox-classic/commit/76f4c275a2fc685080734e8f11c461dc8104734f))
* drafts ([5ed22f3](https://github.com/postalsys/inbox-classic/commit/5ed22f38eb9a37aa60b6f739ab70285deee87cfa))
* fold earlier messages, find servers like EmailEngine ([8199129](https://github.com/postalsys/inbox-classic/commit/81991295d840dcc15a00ec334e89f79d15a102c5))
* folders, accounts and Find ([5913ebe](https://github.com/postalsys/inbox-classic/commit/5913ebe2752a014c7166c5552661c7918808027a))
* **imap:** IMAP connection with TLS, authentication, mailboxes, messages and IDLE ([3f0acea](https://github.com/postalsys/inbox-classic/commit/3f0acead6000adfa1b41f9fcbd5d7b9007e15a36))
* **imap:** response framing, parser and command compiler ported from imapflow ([9ab7aa5](https://github.com/postalsys/inbox-classic/commit/9ab7aa5afced71a024caae30a4fe59ce72a6d896))
* **mime,imap:** encoded words, parameters, dates, envelopes and body structures ([c5e3f89](https://github.com/postalsys/inbox-classic/commit/c5e3f897cb80e4536a4b86073597a02af8be4c69))
* **mime:** message parser ported from postal-mime, inline images in the preview ([5f980e5](https://github.com/postalsys/inbox-classic/commit/5f980e54a4593fc92045b3ff543a10506b1de583))
* **oauth:** a designed page in the browser after signing in ([687da26](https://github.com/postalsys/inbox-classic/commit/687da26623a1d7da93468650cb530a00f1157989))
* **oauth:** explain when a Microsoft 365 organization must approve the app ([2feff6d](https://github.com/postalsys/inbox-classic/commit/2feff6d3dd590bbc32e1072c1972dfd6718be702))
* **oauth:** Gmail sign-in through the browser in every build ([543d77d](https://github.com/postalsys/inbox-classic/commit/543d77d532100743b4a51a71832ac34d89e7217e))
* **oauth:** sign in to Gmail and Outlook.com through the browser ([dc76218](https://github.com/postalsys/inbox-classic/commit/dc76218728510edf34ad1c0175b894187280c033))
* Outbox and Send Later, Save As, Import and Print ([aa16396](https://github.com/postalsys/inbox-classic/commit/aa16396798db8d66f8d197664259768063c7bdc1))
* **reading:** message views built off the window thread ([0ea6f6f](https://github.com/postalsys/inbox-classic/commit/0ea6f6f6efd41de10f4e633be17d60069e961baf))
* **smtp,core,app:** send mail, reply and forward ([5423868](https://github.com/postalsys/inbox-classic/commit/542386829c7656183db7fd48a37cd24b56a1e347))
* **store,sync:** SQLite message store and IMAP folder sync ([2a4a69d](https://github.com/postalsys/inbox-classic/commit/2a4a69de5f36db65f58f063976bd4412a84ce455))
* **tree:** accounts with the same name show their address ([456f4f1](https://github.com/postalsys/inbox-classic/commit/456f4f19fde4b6e5099d3441b1e9737ca888f73e))
* UI end-to-end test, in-app help, encryption-required errors ([ab6354e](https://github.com/postalsys/inbox-classic/commit/ab6354eca9fdb21ef180df4c6e1cbb21fc178157))
* **ui:** Accounts as a list with columns ([305a3c0](https://github.com/postalsys/inbox-classic/commit/305a3c0bed1738e0f3fddc86508871d2dafdb54c))
* **ui:** Fluent icons on the toolbars ([7120b0a](https://github.com/postalsys/inbox-classic/commit/7120b0a81add84f7da145fa623cff396416565ce))
* **ui:** Outlook Express layout details, Message Properties ([9e30017](https://github.com/postalsys/inbox-classic/commit/9e300179e80f941f476a4b68a3efa605f62fd6e0))
* **ui:** print window, Outlook Express reading pane bars, app icon ([b9f3d53](https://github.com/postalsys/inbox-classic/commit/b9f3d5322e4d8b298b5f008ffe07436dd591d99b))
* **ui:** removable attachments, Outbox columns, grouped toolbars ([a6bb9d9](https://github.com/postalsys/inbox-classic/commit/a6bb9d969bbb1413cf46ecb350a4e297ba0f391a))


### Bug Fixes

* **mime:** a Date zone that cuts a character no longer panics ([e30b6fe](https://github.com/postalsys/inbox-classic/commit/e30b6fe307a4c12ce69974a5a383a83c4fc1ae38))
* **net:** resume TLS sessions only for platform trust ([51652b4](https://github.com/postalsys/inbox-classic/commit/51652b4d74238c4a0e25c82aa668af77515c0e83))
* **oauth:** Microsoft sign-in comes back to localhost ([c4bac74](https://github.com/postalsys/inbox-classic/commit/c4bac7477f93ff0f04349b34b47d7362b957ca54))
* **security:** mark saved attachments and messages as from the internet ([54f716c](https://github.com/postalsys/inbox-classic/commit/54f716c0957050bdaf370cf0e335b695c9d5a5e3))
* **ui:** offer Download pictures only for messages that have them ([6a7287c](https://github.com/postalsys/inbox-classic/commit/6a7287c642eca458e7d1ab8dbcb43a476ef83899))
* **ui:** Size column wide enough for 1023 bytes ([87f96c2](https://github.com/postalsys/inbox-classic/commit/87f96c28b49d73f1c18a49f042c2e361d97c8e67))
