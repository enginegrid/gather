require "rails_helper"

describe Work::Shift do
  # This ensures that times aren't UTC even when there is a non-UTC timezone.
  before { Time.zone = "Saskatchewan" }

  describe "normalization" do
    let(:job) { build(:work_job, hours: 2) }
    let(:shift) { build(:work_shift, submitted.merge(job: job)) }

    # Get the normalized values for the submitted keys.
    subject { submitted.keys.map { |k| [k, shift.send(k)] }.to_h }

    describe "slots" do
      context "full community job" do
        before do
          allow(shift).to receive(:job_full_community?).and_return(true)
          shift.send(:normalize)
        end

        context "changes slots to 1m" do
          let(:submitted) { {slots: 3} }
          it { is_expected.to eq(slots: 1e6) }
        end
      end

      context "fixed slot job" do
        before do
          allow(shift).to receive(:job_full_community?).and_return(false)
          shift.send(:normalize)
        end

        context "leaves slots value unchanged" do
          let(:submitted) { {slots: 3} }
          it { is_expected.to eq(slots: 3) }
        end
      end
    end

    describe "start and end times" do
      context "job with date_time type" do
        before do
          allow(shift).to receive(:job_date_time?).and_return(true)
          shift.send(:normalize)
        end

        context "leaves times unchanged" do
          let(:submitted) { {starts_at: "2018-01-01 12:30", ends_at: "2018-01-01 14:30"} }
          it { is_expected.to eq(starts_at: tp("2018-01-01 12:30"), ends_at: tp("2018-01-01 14:30")) }
        end
      end

      context "full period job" do
        before do
          allow(shift).to receive(:job_date_time?).and_return(false)
          allow(shift).to receive(:job_full_period?).and_return(true)
          allow(shift).to receive(:period_starts_on).and_return(Date.parse("2018-01-01"))
          allow(shift).to receive(:period_ends_on).and_return(Date.parse("2018-02-28"))
          shift.send(:normalize)
        end

        context "sets times to period start/end" do
          let(:submitted) { {starts_at: "", ends_at: ""} }
          it { is_expected.to eq(starts_at: tp("2018-01-01 00:00"), ends_at: tp("2018-02-28 23:59")) }
        end
      end

      context "job with date_only type" do
        before do
          allow(shift).to receive(:job_date_only?).and_return(true)
          shift.send(:normalize)
        end

        context "sets times to midnight" do
          let(:submitted) { {starts_at: "2018-01-01 12:30", ends_at: "2018-01-02 14:30"} }
          it { is_expected.to eq(starts_at: tp("2018-01-01 00:00"), ends_at: tp("2018-01-02 23:59")) }
        end
      end

      def tp(str)
        Time.zone.parse(str)
      end
    end
  end

  describe "validation" do
    let(:job) { build(:work_job, hours: 2) }

    describe "start must be before end" do
      it "is valid when start before end" do
        shift = build(:work_shift, job: job, starts_at: "2018-01-01 12:30", ends_at: "2018-01-01 14:30")
        expect(shift).to be_valid
      end

      it "adds error when times equal" do
        shift = build(:work_shift, job: job, starts_at: "2018-01-01 12:30", ends_at: "2018-01-01 12:30")
        expect(shift).not_to be_valid
        expect(shift.errors[:ends_at].join).to match /must be after start time/
      end

      it "adds error when start after end" do
        shift = build(:work_shift, job: job, starts_at: "2018-01-01 13:30", ends_at: "2018-01-01 12:30")
        expect(shift).not_to be_valid
        expect(shift.errors[:ends_at].join).to match /must be after start time/
      end
    end

    context "elapsed hours must equal or evenly divide job hours for date_time jobs" do
      let(:shift) { build(:work_shift, job: job) }

      before { allow(shift).to receive(:job_hours).and_return(1.5) }

      shared_examples_for "elapsed hours must equal job hours" do
        it "is valid with correct elapsed time" do
          shift.assign_attributes(starts_at: "2018-01-01 10:30", ends_at: "2018-01-01 12:00")
          expect(shift).to be_valid
        end

        it "is invalid with incorrect elapsed time" do
          shift.assign_attributes(starts_at: "2018-01-01 10:30", ends_at: "2018-01-01 12:01")
          expect(shift).not_to be_valid
          expect(shift.errors[:starts_at].join).to eq "Shift must last for 1.5 hours"
        end
      end

      context "without date_time time_type" do
        before { allow(shift).to receive(:job_date_time?).and_return(false) }

        it "is valid with any elapsed time" do
          shift.assign_attributes(starts_at: "2018-01-01", ends_at: "2018-01-04")
          expect(shift).to be_valid
        end
      end

      context "with date_time time_type" do
        before { allow(shift).to receive(:job_date_time?).and_return(true) }
        before { allow(shift).to receive(:job_slot_type).and_return(slot_type) }

        context "with fixed slot_type" do
          let(:slot_type) { "fixed" }
          it_behaves_like "elapsed hours must equal job hours"
        end

        context "with full_single slot_type" do
          let(:slot_type) { "full_single" }
          it_behaves_like "elapsed hours must equal job hours"
        end

        context "with full_multiple slot_type" do
          let(:slot_type) { "full_multiple" }

          it "is valid if elapsed time equals job hours" do
            shift.assign_attributes(starts_at: "2018-01-01 10:30", ends_at: "2018-01-01 12:00")
            expect(shift).to be_valid
          end

          it "is valid if elapsed time evenly divides job hours" do
            shift.assign_attributes(starts_at: "2018-01-01 10:30", ends_at: "2018-01-01 11:15")
            expect(shift).to be_valid
          end

          it "is invalid if elapsed time doesn't evenly divide job hours" do
            shift.assign_attributes(starts_at: "2018-01-01 10:30", ends_at: "2018-01-01 11:30")
            expect(shift).not_to be_valid
            expect(shift.errors[:starts_at].join).to eq "Shift length must equal or evenly divide 1.5 hours"
          end
        end
      end
    end
  end

  # Need to clean with truncation because we are doing stuff with txn isolation which is forbidden
  # inside nested transactions.
  describe ".signup_user", database_cleaner: :truncate do
    let(:job) { create(:work_job, shift_slots: 2) }
    let(:shift) { job.shifts.first }
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:assignment1) { create(:work_assignment, shift: shift, user: user1) }

    context "with available slots" do
      context "normal conditions" do
        it "creates assignment and updates counter cache" do
          shift.signup_user(user2.id)
          expect(shift.reload.assignments.count).to eq 2
          expect(shift.assignments_count).to eq 2
        end
      end

      context "if user already signed up" do
        it "raises error" do
          expect { shift.signup_user(user1.id) }.to raise_error(Work::AlreadySignedUpError)
        end
      end

      context "with two competing requests" do
        before do
          # We insert a new assignment via second database connection immediately AFTER the main
          # connection (Shift model) retrieves the current assignment count but BEFORE it adds its own
          # assignment to the DB.
          allow(shift).to receive(:current_assignments_count) do
            count = shift.reload.assignments_count
            db = ApplicationRecord.establish_connection.connection
            db.execute("INSERT INTO work_assignments (user_id, shift_id, cluster_id, created_at, updated_at)
              VALUES (#{user2.id}, #{shift.id}, #{shift.cluster_id}, NOW(), NOW())")
            db.execute("UPDATE work_shifts SET assignments_count = COALESCE(assignments_count, 0) + 1
              WHERE id = #{shift.id}")
            count
          end
        end

        # This spec won't pass (i.e. both assignments will be inserted, thus exceeding the limit)
        # unless we use isolation: :repeatable_read on the transaction in the method.
        it "raises error for second request" do
          expect { shift.signup_user(user3.id) }.to raise_error(Work::SlotsExceededError)
        end
      end
    end

    context "without available slots" do
      let!(:assignment2) { create(:work_assignment, shift: shift, user: user2) }

      it "raises error" do
        expect { shift.signup_user(user2.id) }.to raise_error(Work::SlotsExceededError)
      end
    end
  end
end
