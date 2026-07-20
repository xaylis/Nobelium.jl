# Shared test doubles: a transport that records requests and replays canned
# responses, plus an API wired to it with a no-op sleeper.

using HTTP
using Nobelium: RateLimiter, Route, request

struct FakeHTTP
    requests::Vector{Any}
    responses::Vector{Any}
end
fakehttp(responses...) = FakeHTTP(Any[], collect(Any, responses))

function (fake::FakeHTTP)(method, url, headers, body)
    push!(fake.requests, (; method, url, headers, body))
    r = popfirst!(fake.responses)
    r isa Exception ? throw(r) : r
end

response(status; body="", headers=Pair{String,String}[]) =
    HTTP.Response(status, headers; body=Vector{UInt8}(codeunits(body)))

fastapi(fake; token="test-token") =
    API(token; http=fake, limiter=RateLimiter(sleeper=_ -> nothing))

# Body of the last request the fake saw, parsed.
sent_json(fake::FakeHTTP) = JSON3.read(last(fake.requests).body)
