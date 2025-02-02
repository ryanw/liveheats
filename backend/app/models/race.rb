class Race < ApplicationRecord
  has_many :lanes, -> { order(:sort) }, dependent: :destroy
  accepts_nested_attributes_for :lanes, allow_destroy: true
  before_save :remove_empty_lanes
  before_save :update_lane_sort

  validates :name, presence: true, format: { with: /\S/, message: 'cannot be blank' }
  validate :validate_minimum_lane_count
  validate :validate_finish_places

  private
    def validate_minimum_lane_count
      if lanes.size < 2
        errors.add(:lanes, 'must have at least 2 lanes')
      end
    end

    def validate_finish_places
      next_place = 1
      prev_place = 1
      sorted_lanes = lanes
        .filter { |lane| not lane.name.nil? and not lane.competitor&.position.nil? }
        .sort { |a, b| a.competitor.position <=> b.competitor.position }

      for lane in sorted_lanes
        if lane.competitor.position != next_place and lane.competitor.position != prev_place
          errors.add(:competitor, "is in an invalid position. Expected #{next_place} got #{lane.competitor.position}")
        end

        next_place += 1
        prev_place = lane.competitor.position
      end
    end

    def remove_empty_lanes
      self.lanes = lanes.filter { |lane| not lane.name.nil? }
    end

    def update_lane_sort
      self.lanes = lanes.map.with_index do |lane, i|
        lane[:sort] = i
        lane
      end
    end
end
