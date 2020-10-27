import { createClient } from "@supabase/supabase-js/lib/index";
import "regenerator-runtime/runtime.js";
const SUPABASE_URL = "https://hekmowidmplrkjvthddi.supabase.co";
const supabase = createClient(SUPABASE_URL, process.env.supabaseKey);

export default function () {
  const read = supabase
    .from("read")
    .on("*", (payload) => {
      console.log("Change received!", payload);
    })
    .subscribe();
}
