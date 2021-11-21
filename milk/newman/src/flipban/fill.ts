const newman = require('newman')
const yargs = require('yargs/yargs')
import { NewmanJson, CreateTeam, Item } from '../utils/interfaces'

const argv = yargs(process.argv.slice(2))
    .options({
        tournament_id: { type: 'number', default: 1}
    })
    .argv

function teamItems(teamCount: number): Item[] {
    let items: Item[] = []
    for (let i=2; i<=teamCount*5+2; i+=5) {
        const teamJson: CreateTeam = {
            tournament_id: 1,
            size:          5,
            leader_id:     i,
            user_id_list:  [i+1, i+2, i+3, i+4]
        }

        items.push({
            name: 'Create Team',
            request: {
                url: 'http://localhost:3000/api/team',
                method: 'POST',
                header: [
                    {
                        key: 'Content-Type',
                        value: 'application/json'
                    }
                ],
                body: {
                    mode: 'raw',
                    raw: JSON.stringify(teamJson)
                }
            }
        })
    }

    return items
}

const newmanJson: NewmanJson = {
    info: {
        name: 'Create team request'
    },
    item: teamItems(4)
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