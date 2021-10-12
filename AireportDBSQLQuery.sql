CREATE DATABASE [Airport]

USE [Airport]

/****** Create database ******/
CREATE TABLE [Planes](
             [Id] INT PRIMARY KEY IDENTITY,
			 [Name] VARCHAR(30) NOT NULL,
			 [Seats] INT NOT NULL,
			 [Range] INT NOT NULL
);

CREATE TABLE [Flights](
			 [Id] INT PRIMARY KEY IDENTITY,
			 [DepartureTime] DATETIME,
			 [ArrivalTime] DATETIME,
			 [Origin] VARCHAR(50) NOT NULL,
			 [Destination] VARCHAR(50) NOT NULL,
			 [PlaneId] INT FOREIGN KEY REFERENCES [Planes](Id) NOT NULL
);

CREATE TABLE [Passengers](
			 [Id] INT PRIMARY KEY IDENTITY NOT NULL,
			 [FirstName] VARCHAR(30) NOT NULL,
			 [LastName] VARCHAR(30) NOT NULL,
			 [Age] INT NOT NULL,
			 [Address] VARCHAR(30) NOT NULL,
			 [PassportId] VARCHAR(11) NOT NULL,
);

CREATE TABLE [LuggageTypes](
			 [Id] INT PRIMARY KEY IDENTITY NOT NULL,
			 [Type] VARCHAR(30) NOT NULL
);

CREATE TABLE [Luggages](
			 [Id] INT PRIMARY KEY IDENTITY,
			 [LuggageTypeId] INT FOREIGN KEY REFERENCES [LuggageTypes](Id) NOT NULL,
			 [PassengerId] INT FOREIGN KEY REFERENCES [Passengers](Id) NOT NULL
);

CREATE TABLE [Tickets](
			 [Id] INT PRIMARY KEY IDENTITY ,
			 [PassengerId] INT FOREIGN KEY REFERENCES [Passengers](Id) NOT NULL,
			 [FlightId] INT FOREIGN KEY REFERENCES [Flights](Id) NOT NULL,
			 [LuggageId] INT FOREIGN KEY REFERENCES [Luggages](Id) NOT NULL,
			 [Price] DECIMAL(18,2) NOT NULL
);

/****** 2. Insert ******/

INSERT INTO [Planes]([Name], [Seats], [Range])
VALUES
      ('Airbus 336', 112, 5132),
      ('Airbus 330', 432, 5325),
      ('Boeing 369', 231, 2355),
      ('Stelt 297', 254, 2143),
      ('Boeing 338', 165, 5111),
      ('Airbus 558', 387, 1342),
      ('Boeing 128', 345, 5541)

INSERT INTO [LuggageTypes]([Type])
VALUES
      ('Crossbody Bag'),
      ('School Backpack'),
      ('Shoulder Bag')

/****** 3. Update ******/
SELECT t.[Price] 
FROM [Flights] AS f
JOIN [Tickets] AS t ON f.Id = t.Id
WHERE [Destination] = 'Carlsbad'
UPDATE [Tickets]
SET [Price] = Price + ([Price] * 0.13)

/****** 4. Delete ******/
ALTER TABLE [Tickets] WITH CHECK ADD CONSTRAINT FK__Tickets__FlightI__440B1D61d FOREIGN KEY ([FlightId])
REFERENCES [Flights]
ON DELETE CASCADE 

DELETE FROM [Flights]
WHERE Destination = 'Ayn Halagim'

/****** 5. Select All Planes with Name Containing 'Tr' ******/
SELECT * 
FROM [Planes]
WHERE [Name] LIkE '%tr%'
ORDER BY [Id], [Name], [Seats], [Range]

/****** 6. Flights Total Price ******/
SELECT FlightId, SUM(Price) AS Price
FROM [Tickets]
GROUP BY [FlightId]
ORDER BY [Price] DESC, [FlightId]

/****** 7. Passanger Trips ******/
SELECT CONCAT([FirstName], ' ', [LastName]) AS [Full Name],
       Origin,
	   Destination
FROM [Passengers] AS p
JOIN [Tickets] AS t ON p.[Id] = t.PassengerId
JOIN [Flights] AS f ON t.[FlightId] = f.Id
ORDER BY [Full Name], Origin, Destination

/****** 8. Non Adventures People ******/
SELECT p.[FirstName], p.[LastName], p.[Age] 
FROM [Passengers] AS p
LEFT JOIN [Tickets] AS t ON p.Id = t.PassengerId
WHERE t.Id IS NULL
ORDER BY p.Age DESC, p.FirstName, p.LastName

/****** 9. Full Info ******/
SELECT CONCAT(p.[FirstName], ' ', p.[LastName]) AS [Full Name],
       pl.[Name] AS [Plane Name],
	   CONCAT(f.[Origin],' - ', f.[Destination]) AS [Trip],
	   lt.[Type] AS [Luggage Type]
FROM [Passengers] AS p
JOIN [Tickets] AS t ON p.Id = t.PassengerId
JOIN [Flights] AS f ON t.FlightId = f.Id
JOIN [Planes] AS pl ON f.PlaneId = pl.Id
JOIN [Luggages] AS l ON t.LuggageId = l.Id
JOIN [LuggageTypes] AS lt ON l.LuggageTypeId = lt.Id
WHERE t.Id IS NOT NULL
ORDER BY [Full Name], [Plane Name], [Trip], [Luggage Type]

/****** 10. PSP ******/

SELECT pl.[Name] AS [Plane Name], pl.Seats, COUNT(t.Id) AS [Passengers Count] 
FROM [Planes] AS pl
LEFT JOIN [Flights] AS f ON pl.Id = f.PlaneId
LEFT JOIN [Tickets] AS t ON f.Id = t.FlightId
GROUP BY pl.Id, pl.[Name], pl.Seats
ORDER BY [Passengers Count] DESC, [Plane Name], pl.[Seats]

/****** 11. Function Creation ******/
CREATE OR ALTER FUNCTION udf_CalculateTickets(@origin VARCHAR(50), @destination VARCHAR(50), @peopleCount INT)
RETURNS VARCHAR(50) AS
BEGIN
     IF(@peopleCount <= 0) RETURN 'Invalid people count!'
	 IF (NOT EXISTS (SELECT 1 FROM Flights WHERE Origin = @origin AND Destination = @destination)) 
	    RETURN 'Invalid flight!'
	 RETURN CONCAT('Total price ',
	 (SELECT TOP(1) t.Price FROM [Tickets] AS t
	 JOIN [Flights] AS f ON t.FlightId = f.Id
	 WHERE f.Origin = @origin AND f.Destination = @destination) * @peopleCount)
END

/****** 12. Create a Stored Procedure ******/
CREATE PROC usp_CancelFlights
AS 
  BEGIN 
       UPDATE [Flights] SET
	   DepartureTime = NULL, ArrivalTime = NULL
	   WHERE ArrivalTime > DepartureTime
  END

EXEC usp_CancelFlights