import { describe, expect, it } from "vitest";
import {
  ObjectsRepository,
  ProjectsRepository,
  TasksRepository,
  OrganizationsRepository,
  PeopleRepository,
  OpportunitiesRepository,
  ApplicationsRepository,
} from "../repositories";

describe("core repository exports", () => {
  it("exports all first-slice repositories", () => {
    expect(ObjectsRepository).toBeDefined();
    expect(ProjectsRepository).toBeDefined();
    expect(TasksRepository).toBeDefined();
    expect(OrganizationsRepository).toBeDefined();
    expect(PeopleRepository).toBeDefined();
    expect(OpportunitiesRepository).toBeDefined();
    expect(ApplicationsRepository).toBeDefined();
  });
});
