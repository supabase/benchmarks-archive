// uploads all .json files in the output directory to the db
const fs = require('fs').promises
const { createClient } = require('@supabase/supabase-js')

const { supabaseKey, supabaseUrl } = process.env

if (!supabaseKey || !supabaseUrl) {
  console.log('Export supabaseKey and supabaseUrl as environment variables. Exiting.')
  process.exit(0)
}

const supabase = createClient(supabaseUrl, supabaseKey)

function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = (Math.random() * 16) | 0,
      v = c == 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

;(async () => {
  const files = await fs.readdir('./output/')

  for (const file of files) {
    if (file.endsWith('.json')) {
      // valid benchmark file, lets update supabase table
      const benchmarkName = file.split('.json')[0]
      const data = JSON.parse(await fs.readFile(`./output/${file}`))
      const id = uuidv4()

      try {
        await supabase.from('benchmarks').insert([{ id, data, benchmark_name: benchmarkName }])
      } catch (err) {
        console.log('Error writing to the database', err)
      }
    }
  }
})()
