describe("TeamMember model", function() {
  var teamMember;
  beforeEach(function () {
    teamMember = new App.TeamMember({ "timetable_items": [] });
  });

  it("addTimetableItem", function() {
    expect(teamMember.get("timetable_items").length).toEqual(0);
    teamMember.addTimetableItem(
      new App.TimetableItem({})
    );
    expect(teamMember.get("timetable_items").length).toEqual(1);
    console.log(JSON.stringify(teamMember));
  });

  it("removeTimetableItemId", function() {
    teamMember.addTimetableItem(
      new App.TimetableItem({
        id: "id_1",
        "timetable_items": []
      })
    );
    teamMember.addTimetableItem(
      new App.TimetableItem({
        id: "id_2",
        "timetable_items": []
      })
    );
    expect(teamMember.get("timetable_items").length).toEqual(2);
    teamMember.removeTimetableItemId("id_1");
    expect(teamMember.get("timetable_items").length).toEqual(1);
  });
});