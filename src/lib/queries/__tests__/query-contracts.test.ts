import {describe,expect,it} from "vitest";
import {PipelineQueryService,DeadlinesQueryService,OpportunityMatchingQueryService,
 RelationshipsQueryService,CampaignsQueryService,HistoricalAnalyticsQueryService,CareerDashboardQuery} from "../index";
describe("query layer exports",()=>{it("exports dashboard query services",()=>{
 [PipelineQueryService,DeadlinesQueryService,OpportunityMatchingQueryService,RelationshipsQueryService,
 CampaignsQueryService,HistoricalAnalyticsQueryService,CareerDashboardQuery].forEach(x=>expect(x).toBeDefined());
});});
