const newman = require('newman')
const yargs = require('yargs/yargs')
import { NewmanJson, CreateTeam, Item, ConfirmInvitation } from '../utils/interfaces'

const argv = yargs(process.argv.slice(2))
    .options({
        tournament_id: { type: 'number', default: 1 },
        master_as_entrant: { type: 'boolean', default: false }
    })
    .argv

function teamItems(teamCount: number): Item[] {
    let items: Item[] = []
    const initialValue = argv.master_as_entrant ? 1 : 2
    for (let i=initialValue; i<teamCount*5+2; i+=5) {
        const teamJson: CreateTeam = {
            tournament_id: argv.tournament_id,
            size:          5,
            leader_id:     i,
            user_id_list:  [i+1, i+2, i+3, i+4]
        }

        items.push({
            name: 'Create Team',
            request: {
                url: 'http://localhost:4001/api/team',
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

function confirmInvitations(teamCount: number): Item[] {
    let items: Item[] = []
    for (let i=1; i<=teamCount*4; i++) {
        const confirmInvitation: ConfirmInvitation = {
            invitation_id: i
        }

        items.push({
            name: 'Confirm team Invitation',
            request: {
                url: 'http://localhost:4001/api/team/invitation_confirm',
                method: 'POST',
                header: [
                    {
                        key: 'Content-Type',
                        value: 'application/json'
                    }
                ],
                body: {
                    mode: 'raw',
                    raw: JSON.stringify(confirmInvitation)
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
    item: teamItems(4).concat(confirmInvitations(4))
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