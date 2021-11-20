const newman = require('newman')
import { NewmanJson, CreateTournament } from './utils/interfaces'

// NOTE: masterが1の大会を作成する

const tournamentJson: CreateTournament = {
    capacity: 4,
    deadline: "2050-04-17T14:00:00Z",
    description: "asdf",
    enabled_discord_server: false,
    enabled_coin_toss: false,
    enabled_map: false,
    event_date: "2050-04-17T14:00:00Z",
    game_id: 0,
    game_name: "VALORANT",
    is_team: false,
    join: false,
    master_id: 1,
    name: "Basic Individual Tournament",
    platform_id: 1,
    rule: "basic",
    start_recruiting: "2049-04-17T14:00:00Z",
    type: 2
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
                            key: "image",
                            type: "file",
                            enabled: true,
                            src: undefined
                        },
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

