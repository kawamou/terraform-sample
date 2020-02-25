resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id
}
