1. Purpose

This domain tracks discrete recruiting-process events attached to an application,
including:

recruiter screens;

behavioral interviews;

technical interviews;

case interviews;

superdays;

take-home assignments;

coding assessments;

quantitative assessments;

written exercises;

final-round interviews.

Each process event extends one canonical record in public.objects.

2. Core Table

public.interviews_assessments

Column

Purpose

id

Shared UUID from public.objects

application_id

Parent application

event_kind

interview or assessment

round_number

Optional recruiting round sequence

stage_name

Human-readable stage label

interview_type

Behavioral, technical, case, recruiter, etc.

assessment_type

Coding, quantitative, take-home, written, etc.

status

Scheduled/completed/cancelled/etc.

scheduled_start_at

Scheduled start

scheduled_end_at

Scheduled end

deadline_at

Assessment deadline

completed_at

Actual completion timestamp

location_text

Physical location or platform

meeting_url

Video interview or assessment URL

primary_interviewer_person_id

Optional primary interviewer

score

Optional normalized score

score_max

Optional maximum score

result

Pass/fail/advance/reject/pending/etc.

preparation_notes

Preparation notes

feedback_notes

Post-event notes

created_at

Creation timestamp

updated_at

Update timestamp

3. Event Kinds

interview

assessment

4. Interview Types

recruiter_screen

behavioral

technical

case

quantitative

hiring_manager

panel

superday

final_round

informational

other

5. Assessment Types

coding

quantitative

take_home

written

case

personality

situational_judgment

video

other

6. Statuses

planned

scheduled

in_progress

completed

cancelled

missed

7. Results

pending

passed

failed

advanced

rejected

completed_no_score

unknown

8. Integrity Rules

Canonical object must have object_type = 'interview_assessment'.

Parent application must exist and have the same owner.

Linked interviewer must have the same owner.

Interview events may use interview_type; assessment events may use
assessment_type.

Scheduled end cannot precede scheduled start.

Completed events require completed_at.

Score cannot be negative.

score_max, when provided, must be positive and not below score.

9. Workflow Support

Indexes support:

application timeline retrieval;

upcoming interview schedule;

assessment deadline queues;

interviewer lookups;

status/result reporting;

ordered round history.
