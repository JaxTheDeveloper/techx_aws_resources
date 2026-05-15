### API gateway endpoint
https://cer1g072ki.execute-api.us-west-2.amazonaws.com 

### Alternative approaches
**Strategy A/B — serverless-http / @vendia/serverless-express**
is the obvious choice for a production team. three lines of code, well-tested against edge cases (cookies, binary responses, path stripping), and the cold start penalty from the extra dependency is negligible in practice. If I were shipping this for real I'd probably just use this.

**strategy C — aws lambda web adapter**
requies zero javascript changes at all, but I'll have to do a bit of ClickOps... add a layer arn and a shell script. The app, of course, does not know Lambda is being run on it. Will consider for a quick and cheap option for lift-and-ship... which is essentially this scenario. I did not choose this since the additional init duration doesn't worth it.

### Method chosen
Option D: Wrapper event implementation from scratch.
#### Method rationale
I come from an AI backend with some experience with vue/react, the component lifecycle, such as mount, update, unmount maps pretty naturally to how an http request moves through express: middleware runs in order, state is built up, a response is eventually committed and the cycle ends. That mental model made the low-level wiring feel approachable, though much of the node's http library is quite hard to grasp.

I've also used express before for mocking apis, so i had a rough sense of what req/res actually are under the hood. this felt like a good opportunity to stop treating them as magic and actually see how the event-to-request translation works.

**Did I mention that you don't need any changes to the existing `template.yaml`?**

#### Implications on other approaches & cold start times
My assumption going in was that zero extra dependencies means a smaller deployment package, which means faster cold starts. The results backed my claim with 265ms init duration with only express in node_modules. a library like serverless-http adds its own module graph on top of that, and lambda has to load all of it before the first invocation.

Warm invocations came in at 3–5ms, which is essentially just the loopback cost (I created a HTTP server on 127.0.0.1) of proxying through the in-process http server.


### Evaluated metrics
- Cold start (init duration): 265ms
- Warm invocations: consistently 3-5ms
- Memory used: 95-96MB, out of the available 512MB

#### Raw logs (pulled straight from CLoudWatch):
The following logs are captured from API requests during testing of the three Express routes.
```bash
PS D:\Documents\code\xbrain-w5-byol-node-express> & "D:\Program Files\Amazon\AWSSAMCLI\bin\sam.cmd" logs --stack-name byol-node-express --region us-west-2 -t
Access logging is disabled for HTTP API ID (cer1g072ki)
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:30:35.988000+00:00 INIT_START Runtime Version: nodejs:22.v78    Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:4347240e377e6d9179a8724a4c38e9d6805124c642ee77eb18178f0fd1f3bc09
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:30:36.257000+00:00 START RequestId: 52bf7c42-3041-4fe8-b28c-ad8f88e9cb84 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:30:36.382000+00:00 END RequestId: 52bf7c42-3041-4fe8-b28c-ad8f88e9cb84
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:30:36.382000+00:00 REPORT RequestId: 52bf7c42-3041-4fe8-b28c-ad8f88e9cb84       Duration: 124.29 msBilled Duration: 390 ms Memory Size: 512 MB     Max Memory Used: 95 MB  Init Duration: 265.53 ms
XRAY TraceId: 1-6a06cb9b-33ecc29008cf06d83e4c92b3       SegmentId: f5c98e3b5c05162dSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:30:36.906000+00:00 START RequestId: 49fe483d-2170-473b-a7e3-170b1989bfa5 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:30:36.911000+00:00 END RequestId: 49fe483d-2170-473b-a7e3-170b1989bfa5
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:30:36.911000+00:00 REPORT RequestId: 49fe483d-2170-473b-a7e3-170b1989bfa5       Duration: 4.82 ms Billed Duration: 5 ms    Memory Size: 512 MB     Max Memory Used: 95 MB
XRAY TraceId: 1-6a06cb9c-590321270e4a5e973a1c3527       SegmentId: d58ce96d3c285c60Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:07.651000+00:00 START RequestId: 5fb0948a-cdf8-489a-b4ba-a0c81aa04bcf Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:07.721000+00:00 END RequestId: 5fb0948a-cdf8-489a-b4ba-a0c81aa04bcf
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:07.721000+00:00 REPORT RequestId: 5fb0948a-cdf8-489a-b4ba-a0c81aa04bcf       Duration: 69.19 msBilled Duration: 70 ms   Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbbb-67aba72f146f90144f86845f       SegmentId: 63ca5bbe091218adSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:10.599000+00:00 START RequestId: c73e0529-2fd4-4bb4-bd3d-be05bf66897f Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:10.604000+00:00 END RequestId: c73e0529-2fd4-4bb4-bd3d-be05bf66897f
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:10.604000+00:00 REPORT RequestId: c73e0529-2fd4-4bb4-bd3d-be05bf66897f       Duration: 4.93 ms Billed Duration: 5 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbbe-568c6d3f04749c280b8b0727       SegmentId: 672126b243fc70faSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:11.468000+00:00 START RequestId: 897fb51d-035c-4726-89ca-48f983d284af Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:11.479000+00:00 END RequestId: 897fb51d-035c-4726-89ca-48f983d284af
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:11.479000+00:00 REPORT RequestId: 897fb51d-035c-4726-89ca-48f983d284af       Duration: 5.05 ms Billed Duration: 6 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbbf-04430ae3087a56453008220f       SegmentId: 44913912d23b062bSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:12.275000+00:00 START RequestId: 38d34d29-87f5-4dcc-85ee-986213cb9025 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:12.279000+00:00 END RequestId: 38d34d29-87f5-4dcc-85ee-986213cb9025
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:12.279000+00:00 REPORT RequestId: 38d34d29-87f5-4dcc-85ee-986213cb9025       Duration: 3.98 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc0-66e467df461673ed11b79332       SegmentId: f52ea986c6c03111Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:13.050000+00:00 START RequestId: 48858613-3e75-4af5-b694-db0e7f25b727 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:13.053000+00:00 END RequestId: 48858613-3e75-4af5-b694-db0e7f25b727
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:13.053000+00:00 REPORT RequestId: 48858613-3e75-4af5-b694-db0e7f25b727       Duration: 2.97 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc1-6a977d80064e03403a15f36c       SegmentId: aa88c682077f540fSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:13.922000+00:00 START RequestId: 3390ad14-15ce-4560-a44a-2353a87c0dc7 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:13.926000+00:00 END RequestId: 3390ad14-15ce-4560-a44a-2353a87c0dc7
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:13.926000+00:00 REPORT RequestId: 3390ad14-15ce-4560-a44a-2353a87c0dc7       Duration: 3.66 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc1-7639cf064b66f4d43271a3e7       SegmentId: 8234780652337f4fSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:14.697000+00:00 START RequestId: 991da367-7184-4ce1-bd53-b33913f505b7 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:14.703000+00:00 END RequestId: 991da367-7184-4ce1-bd53-b33913f505b7
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:14.703000+00:00 REPORT RequestId: 991da367-7184-4ce1-bd53-b33913f505b7       Duration: 5.95 ms Billed Duration: 6 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc2-7c05d0294908158f2c85be49       SegmentId: da22e24c5ed7a092Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:15.403000+00:00 START RequestId: 391d505e-4587-4f5c-b297-2e6481f705eb Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:15.407000+00:00 END RequestId: 391d505e-4587-4f5c-b297-2e6481f705eb
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:15.407000+00:00 REPORT RequestId: 391d505e-4587-4f5c-b297-2e6481f705eb       Duration: 3.57 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc3-00afe51e4e45b7134686a86a       SegmentId: c673d9d25c41aca8Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:16.466000+00:00 START RequestId: 5dc91b06-f84e-4fb3-a753-90364862f54b Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:16.480000+00:00 END RequestId: 5dc91b06-f84e-4fb3-a753-90364862f54b
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:16.480000+00:00 REPORT RequestId: 5dc91b06-f84e-4fb3-a753-90364862f54b       Duration: 14.96 msBilled Duration: 15 ms   Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc4-0c7f05ce6502e4ca50a1a4c4       SegmentId: 556e2da8b61da52eSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:16.757000+00:00 START RequestId: d090ef0a-a0cc-4d27-a350-4b9776a664bc Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:16.761000+00:00 END RequestId: d090ef0a-a0cc-4d27-a350-4b9776a664bc
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:16.761000+00:00 REPORT RequestId: d090ef0a-a0cc-4d27-a350-4b9776a664bc       Duration: 3.28 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc4-517d5599619672a76c674cf7       SegmentId: e16d6f51d3c0d045Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:17.570000+00:00 START RequestId: bcde7de9-1562-47e4-b03d-d647686cf727 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:17.574000+00:00 END RequestId: bcde7de9-1562-47e4-b03d-d647686cf727
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:17.574000+00:00 REPORT RequestId: bcde7de9-1562-47e4-b03d-d647686cf727       Duration: 3.10 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc5-3e7d5beb292945ae42794165       SegmentId: 46094f9cda7ae991Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:17.828000+00:00 START RequestId: e0b5b201-1f8b-4aad-8fd7-b9cf2cfde100 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:17.832000+00:00 END RequestId: e0b5b201-1f8b-4aad-8fd7-b9cf2cfde100
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:17.832000+00:00 REPORT RequestId: e0b5b201-1f8b-4aad-8fd7-b9cf2cfde100       Duration: 3.15 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc5-779dc13c320602165a1de409       SegmentId: fe76014a487ac413Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:17.996000+00:00 START RequestId: 65734d5c-28dd-4301-9beb-1bc615dcccfe Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18+00:00 END RequestId: 65734d5c-28dd-4301-9beb-1bc615dcccfe
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18+00:00 REPORT RequestId: 65734d5c-28dd-4301-9beb-1bc615dcccfe      Duration: 2.90 ms       Billed Duration: 3 ms      Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc5-2625aeff779f30c378a69c40       SegmentId: 79ae7e71a80ee8e9Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.148000+00:00 START RequestId: 2e2c9580-20a5-449e-8a82-24c260834da1 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.151000+00:00 END RequestId: 2e2c9580-20a5-449e-8a82-24c260834da1
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.151000+00:00 REPORT RequestId: 2e2c9580-20a5-449e-8a82-24c260834da1       Duration: 2.79 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc6-13b39fac258e467b6d197f5e       SegmentId: f66a8505cc14c916Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.280000+00:00 START RequestId: faf19380-5ee3-49da-9bb1-f057723b4e6d Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.283000+00:00 END RequestId: faf19380-5ee3-49da-9bb1-f057723b4e6d
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.283000+00:00 REPORT RequestId: faf19380-5ee3-49da-9bb1-f057723b4e6d       Duration: 3.00 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc6-3848da2d477ec6b058345817       SegmentId: f78975b053c0d224Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.407000+00:00 START RequestId: 697be105-7eb0-4454-b979-c610a1a02e9e Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.410000+00:00 END RequestId: 697be105-7eb0-4454-b979-c610a1a02e9e
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.410000+00:00 REPORT RequestId: 697be105-7eb0-4454-b979-c610a1a02e9e       Duration: 2.80 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc6-4bfbe7ee36405ea109fcfac0       SegmentId: dab7548b98473268Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.591000+00:00 START RequestId: 12cc8451-72bc-4ec1-9177-f9244ed34fb2 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.595000+00:00 END RequestId: 12cc8451-72bc-4ec1-9177-f9244ed34fb2
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.595000+00:00 REPORT RequestId: 12cc8451-72bc-4ec1-9177-f9244ed34fb2       Duration: 2.97 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc6-6a6d5dcc63fbf5e85ff61ef2       SegmentId: 48826c05972c4020Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.740000+00:00 START RequestId: 2da8cf2b-e419-4c03-9ed9-fea047d1c767 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.744000+00:00 END RequestId: 2da8cf2b-e419-4c03-9ed9-fea047d1c767
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.744000+00:00 REPORT RequestId: 2da8cf2b-e419-4c03-9ed9-fea047d1c767       Duration: 3.66 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc6-08fd6e8c7b7d5f7a0c47c8ba       SegmentId: 003e41077f59cad3Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.909000+00:00 START RequestId: 71817d2b-c7ec-46b0-a629-0545fb229880 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.913000+00:00 END RequestId: 71817d2b-c7ec-46b0-a629-0545fb229880
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:18.913000+00:00 REPORT RequestId: 71817d2b-c7ec-46b0-a629-0545fb229880       Duration: 2.69 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc6-1b5ab44b123c6853232e2781       SegmentId: 13774fc21c6e3aa0Sampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:19.069000+00:00 START RequestId: 51b21d81-81cf-4942-b7ba-1c7b724e4d79 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:19.072000+00:00 END RequestId: 51b21d81-81cf-4942-b7ba-1c7b724e4d79
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:19.072000+00:00 REPORT RequestId: 51b21d81-81cf-4942-b7ba-1c7b724e4d79       Duration: 2.84 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc7-0b1edc236cb74dc609a896c0       SegmentId: b1301c106db61fdfSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:20.555000+00:00 START RequestId: fdb32df6-3efa-4f2d-8e7d-72edfb0a74e4 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:20.558000+00:00 END RequestId: fdb32df6-3efa-4f2d-8e7d-72edfb0a74e4
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:20.558000+00:00 REPORT RequestId: fdb32df6-3efa-4f2d-8e7d-72edfb0a74e4       Duration: 2.62 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc8-7b1b1a3a468221bd49adfbac       SegmentId: 40c613b5b7365b0fSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:21.630000+00:00 START RequestId: 72bf481f-8c4c-4bd0-b886-7f7b18a89f91 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:21.633000+00:00 END RequestId: 72bf481f-8c4c-4bd0-b886-7f7b18a89f91
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:21.633000+00:00 REPORT RequestId: 72bf481f-8c4c-4bd0-b886-7f7b18a89f91       Duration: 2.81 ms Billed Duration: 3 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbc9-3991adcb21b07c3a36597a90       SegmentId: 4c4289a2774a924eSampled: true
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:22.657000+00:00 START RequestId: 28e73b4c-f6c9-49f9-8b34-d7ea8d034676 Version: $LATEST
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:22.661000+00:00 END RequestId: 28e73b4c-f6c9-49f9-8b34-d7ea8d034676
2026/05/15/[$LATEST]78cff16def9a48aea639011ad093d2fd 2026-05-15T07:31:22.661000+00:00 REPORT RequestId: 28e73b4c-f6c9-49f9-8b34-d7ea8d034676       Duration: 3.11 ms Billed Duration: 4 ms    Memory Size: 512 MB     Max Memory Used: 96 MB
XRAY TraceId: 1-6a06cbca-140b47191926c08220df3126       SegmentId: f973143abe0ddeb4Sampled: true
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:12.596000+00:00 INIT_START Runtime Version: nodejs:22.v78    Runtime Version ARN: arn:aws:lambda:us-west-2::runtime:4347240e377e6d9179a8724a4c38e9d6805124c642ee77eb18178f0fd1f3bc09
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:12.913000+00:00 START RequestId: dd4ec4da-9c6e-4f97-ae30-6d51b3f92ae0 Version: $LATEST
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:13.100000+00:00 END RequestId: dd4ec4da-9c6e-4f97-ae30-6d51b3f92ae0
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:13.100000+00:00 REPORT RequestId: dd4ec4da-9c6e-4f97-ae30-6d51b3f92ae0       Duration: 186.87 msBilled Duration: 501 ms Memory Size: 512 MB     Max Memory Used: 93 MB  Init Duration: 313.38 ms
XRAY TraceId: 1-6a06cda0-54c3e03a4dbf9a026e940b79       SegmentId: 2c36bbd1a7398d94Sampled: true
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:36.667000+00:00 START RequestId: 80a27dd3-620c-41e5-a946-ef22b30e1090 Version: $LATEST
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:36.679000+00:00 END RequestId: 80a27dd3-620c-41e5-a946-ef22b30e1090
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:36.679000+00:00 REPORT RequestId: 80a27dd3-620c-41e5-a946-ef22b30e1090       Duration: 10.84 msBilled Duration: 11 ms   Memory Size: 512 MB     Max Memory Used: 94 MB
XRAY TraceId: 1-6a06cdb8-776567de57f16339053cbad7       SegmentId: 63dba8d9d85ad316Sampled: true
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:39.516000+00:00 START RequestId: 028ed3cb-2203-404a-bcf1-1a521b3b64b9 Version: $LATEST
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:39.522000+00:00 END RequestId: 028ed3cb-2203-404a-bcf1-1a521b3b64b9
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:39.522000+00:00 REPORT RequestId: 028ed3cb-2203-404a-bcf1-1a521b3b64b9       Duration: 6.27 ms Billed Duration: 7 ms    Memory Size: 512 MB     Max Memory Used: 94 MB
XRAY TraceId: 1-6a06cdbb-2d99840c089aede70bde76e4       SegmentId: a4a1f35761da5571Sampled: true
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:52.261000+00:00 START RequestId: 1afcdf39-f0ce-4cd7-bb9a-506268f68272 Version: $LATEST
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:52.278000+00:00 END RequestId: 1afcdf39-f0ce-4cd7-bb9a-506268f68272
2026/05/15/[$LATEST]17fe3777baf4450691ecfd411b1a44d7 2026-05-15T07:39:52.278000+00:00 REPORT RequestId: 1afcdf39-f0ce-4cd7-bb9a-506268f68272       Duration: 5.97 ms Billed Duration: 6 ms    Memory Size: 512 MB     Max Memory Used: 94 MB
XRAY TraceId: 1-6a06cdc8-3b52900539baf73904ebfe57       SegmentId: fcf95508193e5cb8Sampled: true

```