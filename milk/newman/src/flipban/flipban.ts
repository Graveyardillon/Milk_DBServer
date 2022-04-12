const newman = require('newman')
const yargs = require('yargs/yargs')
import { NewmanJson, CreateTournament } from '../utils/interfaces'
import { parseBool } from '../utils/functions'
import { Urls } from '../utils/urls'

const argv = yargs(process.argv.slice(2))
    .options({
        coin_head_field:        { type: 'string',  default: 'マップ選択' },
        coin_tail_field:        { type: 'string',  default: 'A/D選択' },
        enabled_discord_server: { type: 'boolean', default: false },
        enabled_coin_toss:      { type: 'boolean', default: true },
        enabled_map:            { type: 'boolean', default: true },
        capacity:               { type: 'number',  default: 4 },
        game_name:              { type: 'string',  default: 'VALORANT' },
        is_team:                { type: 'boolean', default: true },
        master_id:              { type: 'number',  default: 1 },
        name:                   { type: 'string',  default: 'FlipBan Team Tournament' },
        platform_id:            { type: 'number',  default: 1 },
        team_size:              { type: 'number',  default: 5 },
        type:                   { type: 'number',  default: 2 },
    })
    .argv

const tournamentJson: CreateTournament = {
    capacity:               argv.capacity,
    coin_head_field:        argv.coin_head_field,
    coin_tail_field:        argv.coin_tail_field,
    deadline:               "2050-04-17T14:00:00Z",
    description:            "asdf",
    enabled_discord_server: parseBool(argv.enabled_discord_server) || false,
    enabled_coin_toss:      parseBool(argv.enabled_coin_toss) || true,
    enabled_map:            parseBool(argv.enabled_map) || true,
    event_date:             "2050-04-17T14:00:00Z",
    game_name:              argv.game_name,
    is_team:                argv.is_team,
    join:                   false,
    maps:                   [
        { name: "アイスボックス", icon: undefined },
        { name: "アセント",      icon: undefined },
        { name: "バインド",      icon: undefined },
        { name: "ヘイブン",      icon: undefined },
        { name: "ブリーズ",      icon: undefined },
        { name: "スプリット",    icon: undefined }
    ],
    master_id:              argv.master_id,
    name:                   argv.name,
    platform_id:            argv.platform_id,
    rule:                   "flipban",
    start_recruiting:       "2049-04-17T14:00:00Z",
    team_size:              argv.team_size,
}

const newmanJson: NewmanJson = {
    info: {
        name: 'Flip tournament request'
    },
    item: [
        {
            name: 'Flip tournament',
            request: {
                url: Urls.createTournament,
                method: 'POST',
                header: [
                    {
                        key: 'Content-Type',
                        value: 'multipart/form-data'
                    }
                ],
                body: {
                    mode: 'formdata',
                    formdata: [
                        {
                            key:     "tournament",
                            type:    "text",
                            enabled: true,
                            value:   JSON.stringify(tournamentJson)
                        },
                        {
                            key:     "token",
                            type:    "text",
                            enabled: true,
                            value:   ""
                        },
                        {
                            key:     "maps",
                            type:    "text",
                            enabled: true,
                            value:   JSON.stringify(tournamentJson.maps)
                        }
                    ]
                }
            }
        }
    ]
}

newman.run({
    collection: newmanJson,
    reporters: 'cli'
}, (err: any, summary: any) => {
    if (err) throw err

    summary.run.executions.forEach((exec: any) => {
        console.log('Request name:', exec.item.name)
        console.log('Response:', JSON.parse(exec.response.stream))
    })
})