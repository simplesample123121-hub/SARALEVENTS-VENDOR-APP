export const dynamic = 'force-static'

export function GET() {
  return new Response('User-agent: *\nAllow: /', {
    headers: { 'content-type': 'text/plain' }
  })
}


