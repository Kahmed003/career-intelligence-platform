import { describe, expect, it } from "vitest";
import {
  ActivityLedgerService,
  ProjectsService,
  TasksService,
  OrganizationsService,
  PeopleService,
  OpportunitiesService,
  ApplicationsService,
} from "../services";

describe("application service exports", () => {
  it("exports the core workflow services", () => {
    expect(ActivityLedgerService).toBeDefined();
    expect(ProjectsService).toBeDefined();
    expect(TasksService).toBeDefined();
    expect(OrganizationsService).toBeDefined();
    expect(PeopleService).toBeDefined();
    expect(OpportunitiesService).toBeDefined();
    expect(ApplicationsService).toBeDefined();
  });
});
