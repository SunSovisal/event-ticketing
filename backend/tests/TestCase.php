<?php

namespace Tests;

use App\Contracts\BakongGateway;
use App\Contracts\PayWayGateway;
use App\Contracts\PushNotifier;
use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Lcobucci\JWT\Token\DataSet;
use Lcobucci\JWT\UnencryptedToken;
use Mockery;
use Tests\Support\FakeBakongGateway;
use Tests\Support\FakePayWayGateway;

abstract class TestCase extends BaseTestCase
{
    protected FakeBakongGateway $bakong;

    protected FakePayWayGateway $payway;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bakong = new FakeBakongGateway;
        $this->app->instance(BakongGateway::class, $this->bakong);

        $this->payway = new FakePayWayGateway;
        $this->app->instance(PayWayGateway::class, $this->payway);

        $this->app->instance(PushNotifier::class, new class implements PushNotifier
        {
            public function notifyEventPublished(Event $event): void {}
        });
    }

    protected function actingAsFirebaseUser(User $user, string $token = 'valid-token'): static
    {
        $claims = new DataSet([
            'sub' => $user->firebase_uid,
            'email' => $user->email,
            'name' => $user->name,
        ], '{}');

        $verifiedToken = Mockery::mock(UnencryptedToken::class);
        $verifiedToken->shouldReceive('claims')->andReturn($claims);

        $this->mock(FirebaseAuth::class, function ($mock) use ($verifiedToken, $token) {
            $mock->shouldReceive('verifyIdToken')
                ->with($token)
                ->andReturn($verifiedToken);
        });

        return $this->withHeader('Authorization', 'Bearer '.$token);
    }
}
