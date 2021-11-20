const newman = require('newman')
const yargs = require('yargs/yargs')
import { NewmanJson, CreateTournament } from './utils/interfaces'
import { parseBool } from './utils/functions'

const argv = yargs(process.argv.slice(2))
    .options({
        enabled_discord_server: { type: 'boolean', default: false },
        enabled_coin_toss:      { type: 'boolean', default: false },
        enabled_map:            { type: 'boolean', default: false },
        capacity:               { type: 'number',  default: 4 },
        game_name:              { type: 'string',  default: 'VALORANT' },
        is_team:                { type: 'boolean', default: false },
        master_id:              { type: 'number',  default: 1 },
        name:                   { type: 'string',  default: 'Basic Individual Tournament' },
        platform_id:            { type: 'number',  default: 1 },
        type:                   { type: 'number',  default: 2 },
    })
    .argv

const tournamentJson: CreateTournament = {
    capacity:               argv.capacity,
    deadline:               "2050-04-17T14:00:00Z",
    description:            "asdf",
    enabled_discord_server: parseBool(argv.enabled_discord_server) || false,
    enabled_coin_toss:      parseBool(argv.enabled_coin_toss) || false,
    enabled_map:            parseBool(argv.enabled_map) || false,
    event_date:             "2050-04-17T14:00:00Z",
    game_name:              argv.game_name,
    is_team:                argv.is_team,
    join:                   false,
    master_id:              argv.master_id,
    name:                   argv.name,
    platform_id:            argv.platform_id,
    rule:                   "basic",
    start_recruiting:       "2049-04-17T14:00:00Z",
    type:                   argv.type
}

const newmanJson: NewmanJson = {
    info: {
        name: 'basic tournament request'
    },
    item: [
        {
            name: 'basic tournament',
            request: {
                url: 'http://localhost:4001/api/tournament',
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
                            key: "tournament",
                            type: "text",
                            enabled: true,
                            value: JSON.stringify(tournamentJson)
                        },
                        {
                            key: "token",
                            type: "text",
                            enabled: true,
                            value: ""
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
}, (err: any) => {
    if (err) throw err
    console.log('collection run complete!')
})

