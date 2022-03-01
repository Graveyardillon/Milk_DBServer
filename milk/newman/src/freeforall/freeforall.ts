const newman = require('newman')
const yargs = require('yargs/yargs')
import { NewmanJson, CreateTournament } from '../utils/interfaces'
import { parseBool } from '../utils/functions'
import { Urls } from '../utils/urls'

const argv = yargs(process.argv.slice(2))
    .options({
        enabled_discord_server:  { type: 'boolean', default: false },
        capacity:                { type: 'number',  default: 12 },
        game_name:               { type: 'string',  default: 'TFT' },
        is_team:                 { type: 'boolean', default: false },
        master_id:               { type: 'number',  default: 1 },
        name:                    { type: 'string',  default: 'FreeForAll Team Tournament' },
        platform_id:             { type: 'number',  default: 1 },
        team_size:               { type: 'number',  default: 5 },
        round_number:            { type: 'number',  default: 3 },
        match_number:            { type: 'number',  default: 2 },
        round_capacity:          { type: 'number',  default: 4 },
        enable_point_multiplier: { type: 'boolean', default: false}
    })
    .argv

let pointMultiplierCategories: {name: string, multiplier: number}[] = []
if (argv.enable_point_multiplier) {
    pointMultiplierCategories = [
        {name: 'キルポイント', multiplier: 20},
        {name: 'ダメージポイント', multiplier: 0.5}
    ]
}

const tournamentJson: CreateTournament = {
    capacity:                    argv.capacity,
    deadline:                    "2050-04-17T14:00:00Z",
    description:                "asdf",
    enabled_discord_server:      parseBool(argv.enabled_discord_server) || false,
    event_date:                  "2050-04-17T14:00:00Z",
    game_name:                   argv.game_name,
    is_team:                     argv.is_team,
    join:                        false,
    master_id:                   argv.master_id,
    name:                        argv.name,
    platform_id:                 argv.platform_id,
    rule:                        "freeforall",
    start_recruiting:            "2049-04-17T14:00:00Z",
    team_size:                   argv.team_size,
    round_number:                argv.round_number,
    match_number:                argv.match_number,
    round_capacity:              argv.round_capacity,
    enable_point_multiplier:     argv.enable_point_multiplier,
    point_multiplier_categories: pointMultiplierCategories
}

const newmanJson: NewmanJson = {
    info: {
        name: 'Free for all tournament request'
    },
    item: [
        {
            name: 'Free for all tournament',
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
                            key: 'tournament',
                            type: 'text',
                            enabled: true,
                            value:   JSON.stringify(tournamentJson)
                        },
                        {
                            key:     "token",
                            type:    "text",
                            enabled: true,
                            value:   ""
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